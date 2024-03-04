classdef inventory_store < handle
    %In questa classe gestisco l'inventario del negozio, quindi devo
    %aggiornarlo sia in base ai prodotti venduti, che in base ai prodotti
    %scaduti. Per tenere traccia della data di scadenza di ogni prodotto,
    %inventory è un vettore di dimensione self life, dove in inventory(1)
    %ci sono i prodotti che domani scadono e in inventory(end)
    %quelli appena arrivati.

    properties
        self_life
        inventory
    end

    methods
        function obj = inventory_store(self_life, initial_state)
            %tempo di vita del prodotto
            obj.self_life=self_life;

            %numero di prodotti disponibili
            obj.inventory=initial_state;
        end

        %In questo metodo voglio aggiornare l'inventario. Azione da fare a fine
        % giornata, quando scarto i prodotti scaduti.
        function [waste, warehouse] = getwaste(obj)
            %In waste memorizzo il numero di prodotti scartati
            %perchè scaduti.
            waste=obj.inventory(1);

            %Scorro il resto del vettore
            obj.inventory(1:end-1)=obj.inventory(2:end);
            obj.inventory(end)=0;

            %Magazzino:
            warehouse=sum(obj.inventory);
        end

        %Metodo per aggiornare gli ordini arrivati ad inizio giornata
        function getorder (obj, order)
            obj.inventory(end)=order;
        end

        %Ora voglio un metodo che mi aggiorni l'inventario man mano che un
        %prodotto viene venduto. Per come ho strutturato l'inventario,
        %oltre al prodotto venduto mi serve l'informazione sulla vita residua
        %del prodotto.
        function sale_update(obj, age)
            if obj.inventory(age)==0
                error('Si è venduto un prodotto non disponibile')
            else
                obj.inventory(age)=obj.inventory(age)-1; %sto assumendo che ogni cliente può acquistare un solo prodotto alla volta
        
            end
        end

        %Prima di vendere un prodotto però bisogna controllare che sia
        %disponibile nell'inventario. Costruisco un metodo che mi
        %dice se un prodotto di un età specifica è disponibile o meno.
        %Integro qui anche il caso in cui un cliente sia interessato al
        %prodotto indipendentemente dalla sua età, in questo caso passo al
        %metodo età=inf.
        function available=is_available(obj, age)
            if age==inf  %Voglio sapere la disponibilità del prodotto per ogni età, in questo caso available è un vettore
                available=zeros(length(obj.inventory),1);
                for i=1:length(obj.inventory)
                    if obj.inventory(i)==0
                        available(i)=0;
                    else
                        available(i)=1;
                    end
                end
            else  %Questo mi serve nel caso in cui volessi sapere la disponibilità di un prodotto di un età specifica, in questo caso available è un numero
                if obj.inventory(age)==0
                    available=0;
                else
                    available=1;
                end
            end
        end

    end
end