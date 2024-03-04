function performance=daily_simulation(S)
    
    %SCENARIO 1-4: margine variabile con costi mediamente bassi
    products=struct('A', struct('LT', 1, 'SL', 3, 'C', 2, 'P', 4, 'Q', [22 23 24]), ...
                    'B', struct('LT', 3, 'SL', 2, 'C', 1, 'P', 2, 'Q', [19 20]), ...
                    'C', struct('LT', 1, 'SL', 3, 'C', 3, 'P', 5, 'Q', [23 24 25]), ...
                    'D', struct('LT', 2, 'SL', 4, 'C', 2, 'P', 3, 'Q', [17 18 20 21]), ...
                    'E', struct('LT', 2, 'SL', 3, 'C', 1, 'P', 3, 'Q', [17 19 20]));
    %SCENARIO 2: margine fisso di 2 per ogni prodotto
%     products=struct('A', struct('LT', 1, 'SL', 3, 'C', 2, 'P', 4, 'Q', [22 23 24]), ...
%                     'B', struct('LT', 3, 'SL', 2, 'C', 1, 'P', 3, 'Q', [19 20]), ...
%                     'C', struct('LT', 1, 'SL', 3, 'C', 3, 'P', 5, 'Q', [23 24 25]), ...
%                     'D', struct('LT', 2, 'SL', 4, 'C', 4, 'P', 6, 'Q', [17 18 20 21]), ...
%                     'E', struct('LT', 2, 'SL', 3, 'C', 2, 'P', 4, 'Q', [17 19 20]));
%     
    %SCENARIO 3: margine variabile con costi mediamente più alti
%     products=struct('A', struct('LT', 1, 'SL', 3, 'C', 3, 'P', 5, 'Q', [22 23 24]), ...
%                     'B', struct('LT', 3, 'SL', 2, 'C', 2, 'P', 4, 'Q', [19 20]), ...
%                     'C', struct('LT', 1, 'SL', 3, 'C', 3, 'P', 6, 'Q', [23 24 25]), ...
%                     'D', struct('LT', 2, 'SL', 4, 'C', 4, 'P', 6, 'Q', [17 18 20 21]), ...
%                     'E', struct('LT', 2, 'SL', 3, 'C', 2, 'P', 5, 'Q', [17 19 20]));
    
    
%     SCENARIO 4:
%     store=struct('s', [90 100 100 100 130 200 200], 'dist_domanda', 'Poisson', 'mu', 100, ...
%                   'model_choice', struct('type', 'Beta', 'alpha', 2, 'beta', 3));
    
    %SCENARI 1-2-3:
    store=struct('s', [90 100 100 100 130 200 200], 'dist_domanda', 'Poisson', 'mu', 100, ...
                 'model_choice', struct('type', 'custumerType', 'alpha', 2, 'beta', 3));
    
    
    week=52; %1 anno
    day=length(store.s)*week;
    
    initial_state=struct('A', [7 10 0], 'B', [5 0], 'C', ...
                    [7 5 0], 'D', [4 2 6 0], 'E', [5 7 0]);
    k=fieldnames(products);
    for i=1:length(k)
        inventory(i)=inventory_store(products.(k{i}).SL, initial_state.(k{i}));
    end
    
    initial_queue=struct('A', [5, 8], 'B', [5,5,3,3], 'C', [6,6], 'D', [5, 2, 3], 'E', [7, 4, 0]);
    for i=1:length(k)
        order(i)=order_manager(products.(k{i}).LT, initial_queue.(k{i}));
    end
    
    m=[products.A.SL, products.B.SL, products.C.SL, products.D.SL, products.E.SL];
    maxx=max(m); %Questa variabile mi serve per allocare le variabili la quale dimensione dipende dalla self life dei prodotti.
                %Considero quindi la self life più lunga.
    custumer=discrete_model_choice(products, store, maxx);
   
    cost=0;
    revenue=0;
    lost_sale=zeros(1,day);
    sale=zeros(1,day);
    waste=zeros(length(k),1);
    available=zeros(length(k),maxx);


    %SIMULAZIONE GIORNALIERA:
    demand_i=load('demand2.mat');
    demand_i=cell2mat(struct2cell(demand_i));
    custumerType=load('custumer2.mat');
    custumerType=cell2mat(struct2cell(custumerType));
    %(-)FOR sui giorni
    for i=1:day 
        %(-) FOR sui prodotti
        for j=1:length(k) 
            %(-) Aggiorno l'inventario con i nuovi arrivi
            inventory(j).getorder(order(j).order_delivery); 
            %(-) Salvo in una matrice la disponibilità di ogni prodotto per ogni
            %età (ogni riga corrisponde ad un prodotto diverso)
            available(j,1:products.(k{j}).SL)=inventory(j).is_available(inf);
        end
        %(-) FOR sui clienti per calcolare la loro utilità
        for d=1:demand_i(i) 
            choice=custumer.utility_function(products, available, custumerType(i,d));
            if choice(1)==-1 %Non ho venduto nulla, allora passo ad un altro cliente
                lost_sale(i)=lost_sale(i)+1; %Conteggio delle vendite perse
                continue;
            else %Se ho ventuto allora aggiorno l'inventario
                inventory(choice(1)).sale_update(choice(2));
                sale(i)=sale(i)+1; %conteggio vendite
                %(-) Calcolo i ricavi e aggiorno la disponibilità
                switch choice(1)
                    case 1
                        revenue=revenue+products.A.P;
                        available(1, choice(2))=inventory(1).is_available(choice(2));
                    case 2
                        revenue=revenue+products.B.P;
                        available(2, choice(2))=inventory(2).is_available(choice(2));
                    case 3
                        revenue=revenue+products.C.P;
                        available(3, choice(2))=inventory(3).is_available(choice(2));
                    case 4
                        revenue=revenue+products.D.P;
                        available(4, choice(2))=inventory(4).is_available(choice(2));
                    case 5
                        revenue=revenue+products.E.P;
                        available(5, choice(2))=inventory(5).is_available(choice(2));
                end    
            end
        end
        %(-) Faccio di nuovo un for sui prodotti per scartare quelli che
        %scadono e per calcolare l'inventario a fine giornata e fare i nuovi
        %ordini
        for j=1:length(k) 
            [wst, warehouse]=inventory(j).getwaste();
            waste(j)=waste(j)+wst;
            prod_queue=order(j).order_status();
    
            new_order=max(S((j-1)*7+mod(i-1,7)+1)-(prod_queue+warehouse),S(35+j));
%             new_order=max(S(j)-(prod_queue+warehouse),S(5+j));
            
            order(j).neworder(new_order);

            %(-) Calcolo i costi
            cost=cost+products.(k{j}).C*new_order;
        end
        profit_history(i)=revenue-cost;
        revenue_history(i)=revenue;
        revenue=0;
        cost_history(i)=cost;
        cost=0;
    end
    %(-) Calcolo al misura di performance che la funzione partileswarm deve
    %minimizzare:
    performance=(-sum(profit_history))/day;

    
end