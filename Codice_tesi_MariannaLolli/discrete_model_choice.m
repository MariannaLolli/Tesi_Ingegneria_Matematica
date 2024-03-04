classdef discrete_model_choice
%IDEA: In questa classe definisco il modello di scelta discreto
%dei clienti. Utilizzo due possibilita per il tipo di funzione
%di utilita da utilizzare: o un'utilita lineare con una
%distribuzione beta che modellizza la porbabilita che un cliente
%compri o meno un prodotto oppure ad ogni ciente che entra in
%negozio associo un tipo di cliente (FIFO, LIFO, scelta del
%prodotto con il prezzo piu basso, quello con rapporto
%qualita-prezzo migliore, prodotto specifico) e calcolo la
%funzione di utilita che mi andra a dire se il cliente comprera
%qualcosa e nel caso quale prodotto sceglie.

    properties
        %La variabile choice serve per memorizzare al suo interno
        %l'indice che rappresenta il prodotto scelto dal cliente
        %e l'eta del prodotto scelto.
        %Se choice=[-1,0], allora il cliente non compra nulla.
        type
        alpha
        beta

        priceA
        qualityA
        priceB
        qualityB
        priceC
        qualityC
        priceD
        qualityD
        priceE
        qualityE

        choice
        m %lunghezza massima della shelf life utile per le allocazioni di memoria
    end

    methods
    %Definiamo un primo metodo a cui passiamo le due strutture
    %definite nel main di prodotti e rivenditore per definire
    %le proprieta della classe 
        function obj = discrete_model_choice(products, store, m)
            obj.type=store.model_choice.type;
            if strcmp(obj.type, 'Beta') || strcmp(obj.type, 'custumerType') 
                    obj.alpha=store.model_choice.alpha;
                    obj.beta=store.model_choice.beta;
                    obj.priceA=products.A.P;
                    obj.qualityA=products.A.Q;
                    obj.priceB=products.B.P;
                    obj.qualityB=products.B.Q;
                    obj.priceC=products.C.P;
                    obj.qualityC=products.C.Q;
                    obj.priceD=products.D.P;
                    obj.qualityD=products.D.Q;
                    obj.priceE=products.E.P;
                    obj.qualityE=products.E.Q;
                    %Inizializzo il vettore contenete la scelta del cliente con [-1, 0]
                    obj.choice=[-1 0];
                    obj.m=m;
            else
                error('No feasible type of model choice');
            end
        end

        %In questo metodo definisco le funzioni di utilita
        %in funzione del tipo di cliente (associato casualmente)
        %e restituisco il prodotto scelto dal cliente.
        %Availability e' una matrice (righe indicano il prodotto
        %e le colonne l'eta) contenente valori binari e mi dice
        %se i prodotti sono disponibili.

        function choice = utility_function(obj, products, availability, custumerType)
            b=betarnd(obj.alpha, obj.beta);
            %Moltiplico prezzi e qualita per il corrispondente
            %vettore di availability, in questo modo utilizzo
            %nella funzione di utilita un vettore dei prezzi
            %e un vettore delle qualita in cui ho valori nulli
            %in corrispondenza dei prodotti non disponbili.
            priceAvA=obj.priceA.*availability(1,1:products.A.SL);
            qualityAvA=obj.qualityA.*availability(1,1:products.A.SL);
            priceAvB=obj.priceB.*availability(2,1:products.B.SL);
            qualityAvB=obj.qualityB.*availability(2,1:products.B.SL);
            priceAvC=obj.priceC.*availability(3,1:products.C.SL);
            qualityAvC=obj.qualityC.*availability(3,1:products.C.SL);
            priceAvD=obj.priceD.*availability(4,1:products.D.SL);
            qualityAvD=obj.qualityD.*availability(4,1:products.D.SL);
            priceAvE=obj.priceE.*availability(5,1:products.E.SL);
            qualityAvE=obj.qualityE.*availability(5,1:products.E.SL);

            if strcmp(obj.type, 'Beta')
            %Calcolo l'utilita per ogni prodotto:
                utilities=zeros(length(fieldnames(products)), obj.m);
                utilities(1,1:products.A.SL)=b*qualityAvA-priceAvA;
                utilities(2,1:products.B.SL)=b*qualityAvB-priceAvB;
                utilities(3,1:products.C.SL)=b*qualityAvC-priceAvC;
                utilities(4,1:products.D.SL)=b*qualityAvD-priceAvD;
                utilities(5,1:products.E.SL)=b*qualityAvE-priceAvE;

                %Cerco il prodotto con utilita maggiore
                valoreMassimo= max(utilities(:));
                if valoreMassimo<=0
                    choice=[-1 0];
                else 
                    [row, column] = find(utilities==valoreMassimo);
                    %Ora gestisco i casi in cui ci sono valori
                    %massimi uguali nella matrice di utilita:
                    %(-) caso in cui il massimo e' solo su
                    %    un prodotto di un eta specifica
                    if length(row)==1
                        choice=[row, column];
                    %(-) caso in cui l'utilita maggiore
                    %   corrisponde a piu prodotti o ad un
                    %   prodotto ma la scelta e' indifferente
                    %   sull'eta.
                    %Assumiamo che il cliente scelga il prodotto
                    %con il prezzo piu basso.
                    else
                        price=0;
                        price_old=1000;
                        for i=1:length(row)
                            switch row(i)
                                case 1
                                    price=products.A.P;
                                case 2
                                    price=products.B.P;
                                case 3
                                    price=products.C.P;
                                case 4
                                    price=products.D.P;
                                case 5
                                    price=products.E.P;
                            end
                            if price<price_old
                                choice=[row(i), column(i)];
                                price_old=price;
                            %(-) caso in cui il prodotto e' uguale
                            %  ma cambia la sua eta il cliente
                            %  sceglie il prodotto piu fresco.
                            elseif price==price_old && row(i)==row(i-1) 
                                choice=[row(i), column(i)];
                            end
                        end
                    end
                end
            end

            if strcmp(obj.type, 'custumerType')
            
            %1=FIFO, 2=LIFO, 3=best price, 4=best quality/price,
            %6=prodotto specifico o nessun acquisto, 5=probablita
            %di acquisto che segue una beta, quindi ricado nel
            %caso precedente:

                %CASO 6:
                %Nel caso in cui il cliente vuole un prodotto
                %specifico, scelgo randomicamnete se compra qualcosa
                %e nel caso quale prodotto sceglie.
                %Scelgo randomicamente anche la freschezza del prodotto
                %sclto
                if custumerType==6
                    choice(1)=randi([1,6]);
                    if choice(1)==6 
                        choice=[-1 0]; 
                    end
                    %Controllo che il prodotto scelto sia disponibile:
                    switch choice(1)
                        case 1
                            choice(2)=randi([1,products.A.SL]);
                            if availability(choice(1), choice(2))==0
                                choice=[-1 0]; 
                            end
                        case 2
                            choice(2)=randi([1,products.B.SL]);
                            if availability(choice(1), choice(2))==0
                                choice=[-1 0]; 
                            end
                        case 3
                            choice(2)=randi([1,products.C.SL]);
                            if availability(choice(1), choice(2))==0
                                choice=[-1 0]; 
                            end
                        case 4
                            choice(2)=randi([1,products.D.SL]);
                            if availability(choice(1), choice(2))==0
                                choice=[-1 0]; 
                            end
                        case 5
                            choice(2)=randi([1,products.E.SL]);
                            if availability(choice(1), choice(2))==0
                                choice=[-1 0]; 
                            end
                    end
                %CASO 1:
                %scelgo randomicamnete il prodotto che il cliente
                %desidera e acquista quello più vicino alla scadenza
                elseif custumerType==1
                    choice=[randi([1,5]), 1];
                    if availability(choice(1), choice(2))==0
                                choice=[-1 0]; 
                    end
                %CASO 2:
                %scelgo randomicamnete il prodotto che il cliente
                %desidera e acquista quello più fresco
                elseif custumerType==2
                    choice(1)=randi([1,5]);
                    switch choice(1)
                        case 1
                            choice(2)=products.A.SL;
                            if availability(choice(1), choice(2))==0
                                choice=[-1 0]; 
                            end
                        case 2
                            choice(2)=products.B.SL;
                            if availability(choice(1), choice(2))==0
                                choice=[-1 0]; 
                            end
                        case 3
                            choice(2)=products.C.SL;
                            if availability(choice(1), choice(2))==0
                                choice=[-1 0]; 
                            end
                        case 4
                            choice(2)=products.D.SL;
                            if availability(choice(1), choice(2))==0
                                choice=[-1 0]; 
                            end
                        case 5
                            choice(2)=products.E.SL;
                            if availability(choice(1), choice(2))==0
                                choice=[-1 0]; 
                            end
                    end
                %CASO 3:
                %Il cliente vuole il prodotto con il prezzo più basso (B), se
                %non presente non compra
                elseif custumerType==3 
                    choice=[2, randi([1,products.B.SL])];
                    if availability(choice(1), choice(2))==0
                        choice=[-1 0];
                    end
                %CASO 4:
                %Il cliente compra il prodotto con il miglior rapporto
                %qualità prezzo tra quelli disponibili
                elseif custumerType==4
                    utilities=zeros(length(fieldnames(products)), obj.m);
                    utilities(1,1:products.A.SL)=qualityAvA./priceAvA;
                    utilities(2,1:products.B.SL)=qualityAvB./priceAvB;
                    utilities(3,1:products.C.SL)=qualityAvC./priceAvC;
                    utilities(4,1:products.D.SL)=qualityAvD./priceAvD;
                    utilities(5,1:products.E.SL)=qualityAvE./priceAvE;
                    utilities(isnan(utilities))=0;
                    if all(utilities(:)==0) 
                        choice=[-1 0];
                    else
                        valoreMassimo= max(utilities(utilities~=0));
                        [row, column] = find(utilities==valoreMassimo);
                        %Ora gestisco i casi in cui ci sono valori
                        %massimi uguali nella matrice di utilita:
                        %(-) caso in cui il massimo e' solo su
                        %    un prodotto di un eta specifica
                        if length(row)==1 
                            choice=[row, column];
                        %(-) caso in cui l'utilita maggiore
                        %   corrisponde a piu prodotti o ad un
                        %   prodotto ma la scelta e' indifferente
                        %   sull'eta.
                        %Assumiamo che il cliente scelga il prodotto
                        %con il prezzo piu basso.
                        else
                            price=0;
                            price_old=1000;
                            for i=1:length(row)
                                switch row(i)
                                    case 1
                                        price=products.A.P;
                                    case 2
                                        price=products.B.P;
                                    case 3
                                        price=products.C.P;
                                    case 4
                                        price=products.D.P;
                                    case 5
                                        price=products.E.P;
                                end
                                if price<price_old
                                    choice=[row(i), column(i)];
                                    price_old=price;
                                %(-) caso in cui il prodotto e' uguale
                                %  ma cambia la sua eta il cliente
                                %  sceglie il prodotto piu fresco.
                                elseif price==price_old && row(i)==row(i-1) 
                                    choice=[row(i), column(i)];
                                end
                            end
                        end
                    end
                %CASO 5:
                %ricado nel caso precedente della Beta
                elseif custumerType==5
                    utilities=zeros(length(fieldnames(products)), obj.m);
                    utilities(1,1:products.A.SL)=b*qualityAvA-priceAvA;
                    utilities(2,1:products.B.SL)=b*qualityAvB-priceAvB;
                    utilities(3,1:products.C.SL)=b*qualityAvC-priceAvC;
                    utilities(4,1:products.D.SL)=b*qualityAvD-priceAvD;
                    utilities(5,1:products.E.SL)=b*qualityAvE-priceAvE;
        
                    %Cerco il prodotto con utilita maggiore
                    valoreMassimo= max(utilities(:));
                    if valoreMassimo<=0
                        choice=[-1 0];
                    else 
                        [row, column] = find(utilities==valoreMassimo);
                        %Ora gestisco i casi in cui ci sono valori
                        %massimi uguali nella matrice di utilita:
                        %(-) caso in cui il massimo e' solo su
                        %    un prodotto di un eta specifica
                        if length(row)==1
                            choice=[row, column];
                        %(-) caso in cui l'utilita maggiore
                        %   corrisponde a piu prodotti o ad un
                        %   prodotto ma la scelta e' indifferente
                        %   sull'eta.
                        %Assumiamo che il cliente scelga il prodotto
                        %con il prezzo piu basso.
                        else
                            price=0;
                            price_old=1000;
                            for i=1:length(row)
                                switch row(i)
                                    case 1
                                        price=products.A.P;
                                    case 2
                                        price=products.B.P;
                                    case 3
                                        price=products.C.P;
                                    case 4
                                        price=products.D.P;
                                    case 5
                                        price=products.E.P;
                                end
                                if price<price_old
                                    choice=[row(i), column(i)];
                                    price_old=price;
                                %(-) caso in cui il prodotto e' uguale
                                %  ma cambia la sua eta il cliente
                                %  sceglie il prodotto piu fresco.
                                elseif price==price_old && row(i)==row(i-1) 
                                    choice=[row(i), column(i)];
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end