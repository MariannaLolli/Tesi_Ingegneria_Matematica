classdef order_manager< handle
    %In questa classe definisco i metodi per gestire le ordinazioni del
    %negozio

    properties
        %ho due variabili per prodotto: lead time nel quale passo il tempo
        %di consegna definito nella stuct products e un vettore queue della
        %lunghezza di lead time + 1 dove in ogni variabile vado a memorizzare
        %le quantità di prodotti che sono stati ordinati ma sono in fase di
        %cosegna. Quindi in queue(1) ho l'ordine che mi arriva oggi 
        %(lead time rimanente pari a zero) e in queue(end) ho l'ordine più 
        %recente che è stato fatto.
        lead_time
        queue
    end

    methods
        function obj = order_manager(lead_time, initial_queue)
            obj.lead_time=lead_time;
            obj.queue=initial_queue;
        end

        %In questo metodo voglio selezionare quali prodotti arriveranno al
        %tempo corrente e aggiornare i vettori queue. In questo modo riesco
        %a gestire anche prodotti che anno leadtime pari a 0.
        function order = order_delivery(obj)
            %order corrisponde alle unità in arrivo oggi.
            order=obj.queue(1);

            %Aggiorno il vettore queue con la coda degli ordini in arrivo:
            obj.queue(1:end-1)=obj.queue(2:end);
            obj.queue(end)=0;
        end

        %Con quest'altro metodo voglio "fare" l'ordinazione.
        %new_order corrisponde al numero di prodotti ordinati al tempo corrente.
        function neworder(obj, new_order)
            obj.queue(end)=new_order;
        end

        %Con questo metodo voglio calcolae il numero di prodotti che sono
        %in consegna:
        function num_prod=order_status(obj)
            num_prod=sum(obj.queue);
        end
    end
end