classdef scenario_generator < handle
    %In questa classe definisco la generazione degli scenari

    properties
        nu %vettore di stagionalità settimanale del negozio
        dist_domand
        mean       %distribuzione della domanda è una Poisson
        num_scenario
    end

    methods
        function obj = scenario_generator(store, num_scenario)
            %nella struttura che definisce il negozio ho un vettore di
            %stagionalità s (settimanale), la distribuzione con cui voglio
            %generare la domanda e la sua media e varianza, ma che sono
            %giornaliere, non hanno quindi l'informazione sulla
            %stagionalità
            seasonality=store.s;
            %Normalizzo il vettore di stagionalità dividendo ogni
            %componente per la media del vettore stesso. Questo per avere
            %la somma dei fattori di stagionalità pari a 7 per
            %mantenere un ciclo settimanale coerente.
            obj.nu=seasonality/mean(seasonality);
            obj.dist_domand=store.dist_domanda;
            obj.mean=obj.nu*store.mu; %media con stagionalità
            obj.num_scenario=num_scenario;
        end

        function demand = scenario(obj,day)
            %Qui voglio generare la domanda da una Poisson tenendo conto
            %dell'orizzonte temporale, ma anche della stagionalità. Per
            %questo faccio un ciclo for su day, ma per capire a che giorno
            %della settimana mi trovo utilizzo il mod7 di day-1 (-1 perché parte da
            %0 e poi aggiungo 1 sempre per lo stesso motivo).
            demand=zeros(day, obj.num_scenario); %Ogni colonna di queta matrice rappresenta uno scenario
            for j=1:obj.num_scenario
                for i=1:day
                    s=mod(i-1,7)+1; %giorno della settimana
                    demand(i,j)=poissrnd(obj.mean(s));
                end
            end
        end

        function custumerType=custumer_type(obj, demand)
            custumerType=zeros(length(demand), max(demand));
            for i=1:length(demand)
                for j=1:demand(i)
                    %Matrice dove ogni riga corrisponde ad un giorno
                    %diverso di un solo scenario: custumerType(1,5) si
                    %riferisce al quinto cliente del primo giorno
                    custumerType(i,j)=randi([1,6]);
                end
            end
        end

    end
end