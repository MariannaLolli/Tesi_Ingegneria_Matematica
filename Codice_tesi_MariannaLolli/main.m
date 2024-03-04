clear all
close all
clc

%PARTE 1:
% %Genero gli secnari di domanda una sola volta e salvo i risultati su  un
% %file.
% store=struct('s', [90 100 100 100 130 200 200], 'dist_domanda', 'Poisson', 'mu', 100, ...
%                  'model_choice', struct('type', 'custumerType', 'alpha', 2, 'beta', 3));
% week=52; %1 anno
% day=length(store.s)*week;
% %SCENARIO:
% %Inizializzo tutte le variabili utili per utilizzare la classe "simulation"
% %utile per le simulazioni giornaliere
% num_scenario=4;
% scenario=scenario_generator(store, num_scenario);
% %Genero a domanda per ogni scenario:
% demand=scenario.scenario(day);
% %Salvo la domanda su un file e anche il tipo di ogni cliente:
% for i=1:num_scenario
%     demand_i=demand(:,i);
%     file_demand=sprintf('demand%d.mat', i);
%     save(file_demand, 'demand_i');
%     custumerType=scenario.custumer_type(demand_i);
%     file_custumer=sprintf('custumer%d.mat',i);
%     save(file_custumer, 'custumerType');
% end

tic
%PARTE 2:
%POLITICA:
%Ho incapsulato la simulazione giornaliera in daily_simulation e con
%particleswarm calcolo il livello della politica base-stock ottimale:
S=particleswarm(@daily_simulation,40,[20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 0 0 0 0 0],...
                        [100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 20 20 20 20 20]);

S=round(S);
toc



%PARTE 3:
%Con la politica risultante da particleswarm avvio la simulazione per
%studiare i risultati
%Inizializzazioni:

%PRODOTTO:
%Inizializzo i prodotti con un struttura (questo perchè i prodotti hanno
%tempi di vita diversi, quindi per le variabili che descrivono un prodotto
%tramite un vettore, non possono essere considerati come delle matrici
%perché questi vettori hanno lunghezza diversa in base al prodotto).
%Consideriamo 5 diversi prodotti deperibili.
%Le variabili che descrivono un prodotto sono:
%(-) LT rappresenta il tempo (in giorni) di consegna fisso e discreto;
%(-) SL rappresenta il tempo di vita (in giorni) del prodotto j fisso e discreto;
%(-) C è il costo dei prodotti;
%(-) P rappresenta il prezzo di vendita. Se si vuole considerare la
%    possibilità di cambiare il prezzo quando il prodotto è in scadenza, questo
%    diventa un vettore;
%(-) Q è un vettore di qualità del prodotto al passare dei giorni (utile per
%    la funzione di utilità nel modello di scelta).
%SCENARIO 1-4:
products=struct('A', struct('LT', 1, 'SL', 3, 'C', 2, 'P', 4, 'Q', [22 23 24]), ...
                'B', struct('LT', 3, 'SL', 2, 'C', 1, 'P', 2, 'Q', [19 20]), ...
                'C', struct('LT', 1, 'SL', 3, 'C', 3, 'P', 5, 'Q', [23 24 25]), ...
                'D', struct('LT', 2, 'SL', 4, 'C', 2, 'P', 3, 'Q', [17 18 20 21]), ...
                'E', struct('LT', 2, 'SL', 3, 'C', 1, 'P', 3, 'Q', [17 19 20]));
%SCENARIO 2:
% products=struct('A', struct('LT', 1, 'SL', 3, 'C', 2, 'P', 4, 'Q', [22 23 24]), ...
%                     'B', struct('LT', 3, 'SL', 2, 'C', 1, 'P', 3, 'Q', [19 20]), ...
%                     'C', struct('LT', 1, 'SL', 3, 'C', 3, 'P', 5, 'Q', [23 24 25]), ...
%                     'D', struct('LT', 2, 'SL', 4, 'C', 4, 'P', 6, 'Q', [17 18 20 21]), ...
%                     'E', struct('LT', 2, 'SL', 3, 'C', 2, 'P', 4, 'Q', [17 19 20]));
%SCENARIO 3:
% products=struct('A', struct('LT', 1, 'SL', 3, 'C', 3, 'P', 5, 'Q', [22 23 24]), ...
%                 'B', struct('LT', 3, 'SL', 2, 'C', 2, 'P', 4, 'Q', [19 20]), ...
%                 'C', struct('LT', 1, 'SL', 3, 'C', 3, 'P', 6, 'Q', [23 24 25]), ...
%                 'D', struct('LT', 2, 'SL', 4, 'C', 4, 'P', 6, 'Q', [17 18 20 21]), ...
%                 'E', struct('LT', 2, 'SL', 3, 'C', 2, 'P', 5, 'Q', [17 19 20]));

%RIVENDITORE:
%Consideriamo un solo rivenditore.
%Definiamo anch'esso tramite una struttura i cui parametri ci serviranno
%per il modello di scelta.
%Le variabili che descrivono un negozio sono:
%(-) s è un vettore di 7 componenti che rappresenta la stagionaità del
%    negozio (settimanale);        
%(-) distribuzione di domanda definita da:
%    . distribuzione (Poisson);
%    . mu=media -> mu_giornosettimana=mu*s[giornosettimana].
%(-) >se type=Beta allora utilizzo questa distribuzione per il modello di scelta, 
%    ovvero la probabilità che un cliente compri qualcosa segue una Beta(alpha, beta);
%    >se type=custumerType allora all'interno del modello di scelta associo
%    randomicamente un tipo di cliente (FIFO, LIFO, best price, miglior rapporto qualità-prezzo, un prodotto
%    specifico e infine lascio l'opzione precedente in cui la probabilità che un cliente compri qualcosa
%    segue una Beta) e ad ogniuno di essi corrisponde un determinato vettore
%    beta (definiti nella classe discrete_model_choice).
store=struct('s', [90 100 100 100 130 200 200], 'dist_domanda', 'Poisson', 'mu', 100, ...
                 'model_choice', struct('type', 'custumerType', 'alpha', 2, 'beta', 3));

% store=struct('s', [90 100 100 100 130 200 200], 'dist_domanda', 'Poisson', 'mu', 100, ...
%                  'model_choice', struct('type', 'Beta', 'alpha', 2, 'beta', 3));

 %ORIZZONTE TEMPORALE:
%abbiamo una stagionalità settimanale, quindi vogliamo che l'orizzonte di
%tempo sia un multiplo di 7. Per non incorrere in errori, stabiliamo il
%numero di settimane che vogliamo simulare:
week=52; %1 anno
day=length(store.s)*week;

%INVENTARIO:
%Utilizzo un vettore di oggetti
initial_state=struct('A', [7 10 0], 'B', [5 0], 'C', ...
                    [7 5 0], 'D', [4 2 6 0], 'E', [5 7 0]);
k=fieldnames(products);
for i=1:length(k)
    inventory(i)=inventory_store(products.(k{i}).SL, initial_state.(k{i}));
end

 %ORDINI:
%Inizializzo la coda iniziale, ha lunghezza lead time + 1 in quanto in
%queque(1) ho i prodotti con lead time pari a 0, ovvero quelli che sono in
%consegna nel giorno corrente
initial_queue=struct('A', [5, 8], 'B', [5,5,3,3], 'C', [6,6], 'D', [5, 2, 3], 'E', [7, 4, 0]);
for i=1:length(k)
    order(i)=order_manager(products.(k{i}).LT, initial_queue.(k{i}));
end

%CLIENTI:
m=[products.A.SL, products.B.SL, products.C.SL, products.D.SL, products.E.SL];
maxx=max(m); %Questa variabile mi serve per allocare le variabili la quale dimensione dipende dalla self life dei prodotti.
            %Considero quindi la self life più lunga.
custumer=discrete_model_choice(products, store, maxx);

  
%COSTI E RICAVI:
cost=0;
revenue=0;
lost_sale=zeros(1,day);
sale=zeros(1,day);
waste=zeros(length(k),1);
available=zeros(length(k),maxx);
revenue_seasonal=zeros(7,1);
cost_seasonal=zeros(7,1);
lostSale_seas=zeros(7,1);
sale_seas=zeros(7,1);
count_order=0;

%SIMULAZIONE GIORNALIERA:
demand_i=load('demand1.mat');
demand_i=cell2mat(struct2cell(demand_i));
custumerType=load('custumer1.mat');
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
        %BASE-STOCK
%         new_order=max(S((j-1)*7+mod(i-1,7)+1)-(prod_queue+warehouse),0);
        %Sqmin
        new_order=max(S((j-1)*7+mod(i-1,7)+1)-(prod_queue+warehouse),S(35+j));

        count_order=count_order+new_order;
        
        order(j).neworder(new_order);

        %(-) Calcolo i costi
        cost=cost+products.(k{j}).C*new_order;
    end
    profit_history(i)=revenue-cost;
    revenue_history(i)=revenue;
    cost_history(i)=cost;
    revenue_seasonal(mod(i-1,7)+1)=revenue_seasonal(mod(i-1,7)+1)+revenue;
    revenue=0;
    cost_seasonal(mod(i-1,7)+1)=cost_seasonal(mod(i-1,7)+1)+cost;
    cost=0;
end
profit=(sum(revenue_history)-sum(cost_history));
waste_tot=sum(waste);
lostSale_tot=sum(lost_sale);
profit_seasonal=(revenue_seasonal-cost_seasonal);
sale_tot=sum(sale);

for i=1:day
    lostSale_seas(mod(i-1,7)+1)= lostSale_seas(mod(i-1,7)+1)+lost_sale(i);
    sale_seas(mod(i-1,7)+1)= sale_seas(mod(i-1,7)+1)+sale(i);
end

giorni=linspace(1,day,day);
tiledlayout(2,1)
ax1=nexttile;
plot(ax1,giorni, profit_history,'b','LineWidth',1);
hold on;
plot(ax1,giorni, cost_history,'r--','LineWidth',0.5);
plot(ax1,giorni, revenue_history, 'g--','LineWidth',0.5);
xlabel('t');
legend('Profit', 'Cost', 'Revenue');
title(ax1,'Grafico con andamento del profitto');
hold off;
ax2=nexttile;
plot(ax2,giorni, lost_sale,'m-','LineWidth',1);
hold on;
plot(ax2,giorni, sale,'b-','LineWidth',1);
xlabel('t');
legend('Lost sale', 'Sale');
title(ax2,'Grafico con andamento delle vendite');
hold off;