function [matteFallFraction, labileSulphurFraction] = calcMatteFallFraction(m_MgO, m_Al2O3, ... 
    m_SiO2, m_S, m_CaO, m_Cr2O3, m_Fe, m_Co, m_Ni, m_Cu )
    %CALCMATTEFALLFRACTION calculates the matte fall fraction based
    % on flash dryer feed composition
    % all mass inputs should be in grams, and sample is assumed to be 100g
    %   (or equivalently all mass inputs should be in percentage of the
    %   100g sample)

    % molar masses (g/mol)
    % elements
    M_Al = 26.98;
    M_O = 15.999;
    M_Ca = 40.08;
    M_Co = 58.933195;
    M_Cr = 51.996;
    M_Cu = 63.546;
    M_Fe = 55.845;
    M_Mg = 24.305;
    M_Ni = 58.693;
    M_S = 32.066;
    M_Si = 28.0855;

    %% Feed
    M_MgO = M_Mg + M_O;
    M_Al2O3 = 2 * M_Al + 3 * M_O;
    M_SiO2 = M_Si + 2 * M_O;
    M_CaO = M_Ca + M_O;
    M_Cr2O3 = 2 * M_Cr + 3 * M_O;

    feedCompositionCell = {
        'MgO', M_MgO, m_MgO;
        'Al2O3', M_Al2O3, m_Al2O3;
        'SiO2', M_SiO2, m_SiO2;
        'S', M_S, m_S;
        'CaO', M_CaO, m_CaO;
        'Cr2O3', M_Cr2O3, m_Cr2O3;
        'Fe', M_Fe, m_Fe;
        'Co', M_Co, m_Co;
        'Ni', M_Ni, m_Ni;
        'Cu', M_Cu, m_Cu;
    };

    feedCompositionTable = cell2table(feedCompositionCell(:, 2:end), RowNames=feedCompositionCell(:, 1), VariableNames={'M', 'm'});
    feedCompositionTable.Properties.DimensionNames{1} = 'Compound';
    feedCompositionTable.n = feedCompositionTable.m ./ feedCompositionTable.M;
    
    %% Reagents
    M_CuFeS2 = M_Cu + M_Fe + 2 * M_S;
    M_Ni9Fe8S15 = 9 * M_Ni + 8 * M_Fe + 15 * M_S;
    M_CoS = M_Co + M_S;
    M_FeS2 = M_Fe + 2 * M_S;
    M_Fe7S8 =  7 * M_Fe + 8 * M_S;
    M_FeO = M_Fe + M_O;
    
    
    
    reagentCell = {'CuFeS2', M_CuFeS2; 'Ni9Fe8S15', M_Ni9Fe8S15; 'CoS', M_CoS;
        'FeS2', M_FeS2; 'Fe7S8', M_Fe7S8; 'FeO', M_FeO; 'MgO', m_MgO;
        'SiO2', M_SiO2; 'Al2O3', M_Al2O3};
    reagentTable = table([reagentCell{:, 2}]', nan(size(reagentCell, 1), 1), nan(size(reagentCell, 1), 1), RowNames=reagentCell(:, 1), VariableNames={'M', 'm', 'n'});
    reagentTable.Properties.DimensionNames{1} = 'Compound';

    reagentTable('CuFeS2', :).n = feedCompositionTable('Cu', :).n; % Cu -> Chalcopyrite (CuFeS2)
    reagentTable('Ni9Fe8S15', :).n = feedCompositionTable('Ni', :).n / 9; % Ni -> Pentlandite (Ni9Fe8S15)
    reagentTable('CoS', :).n = feedCompositionTable('Co', :).n; % Co -> CoS
    % Remaining sulphur split = 20% FeS2 & 80% Fe7S8
    n_S_Remaining = feedCompositionTable('S', :).n - (reagentTable('CuFeS2', :).n * 2) - (reagentTable('Ni9Fe8S15', :).n * 15) - (reagentTable('CoS', :).n);
    if n_S_Remaining < 0
        % TODO: decide how to log this
        disp("Warning: violated assumption that sulphur is available in excess")
        n_S_Remaining = 0;
    end
    reagentTable('FeS2', :).n = 0.2 * n_S_Remaining / 2;
    reagentTable('Fe7S8', :).n = 0.8 * n_S_Remaining / 8;
    % Remaining Fe -> FeO
    reagentTable('FeO', :).n = feedCompositionTable('Fe', :).n - (reagentTable('CuFeS2', :).n) - (reagentTable('Ni9Fe8S15', :).n * 8) - (reagentTable('FeS2', :).n) - (reagentTable('Fe7S8', :).n * 7);
    reagentTable('MgO', :).n = feedCompositionTable('MgO', :).n;
    reagentTable('SiO2', :).n = feedCompositionTable('SiO2', :).n;
    reagentTable('Al2O3', :).n = feedCompositionTable('Al2O3', :).n;
    
    reagentTable.m = reagentTable.n .* reagentTable.M; % optional calc : may remove for speed

    

    %% Matte products
    % Reactions
    % CuFeS2 -> ½ Cu2S + FeS + ¼ S2
    % Ni9Fe8S15 -> 3 Ni3S2 + 8 FeS + ½ S2
    % FeS2 -> FeS + ½ S2
    % Fe7S8 -> 7FeS + ½ S2

    M_Cu2S = M_Cu * 2 + M_S;
    M_FeS = M_Fe + M_S;
    M_Ni3S2 = M_Ni * 3 + M_S * 2;

    matteCell = {'Cu2S', M_Cu2S; 'FeS', M_FeS; 'Ni3S2', M_Ni3S2; 'CoS', M_CoS};
    matteTable = table([matteCell{:, 2}]', nan(size(matteCell, 1), 1), nan(size(matteCell, 1), 1), RowNames=matteCell(:, 1), VariableNames={'M', 'm', 'n'});
    matteTable.Properties.DimensionNames{1} = 'Compound';
    
    matteTable('Cu2S', :).n = reagentTable('CuFeS2', :).n / 2;
    matteTable('FeS', :).n = reagentTable('CuFeS2', :).n + reagentTable('Ni9Fe8S15', :).n * 8 + reagentTable('FeS2', :).n + reagentTable('Fe7S8', :).n * 7;
    matteTable('Ni3S2', :).n = reagentTable('Ni9Fe8S15', :).n * 3;
    matteTable('CoS', :).n = reagentTable('CoS', :).n;

    matteTable.m = matteTable.n .* matteTable.M;

    matteFallFraction = sum(matteTable.m)/100;
    
    %% Labile Sulphur
    n_S2_labile =  reagentTable('CuFeS2',:).n / 4 + reagentTable('Ni9Fe8S15',:).n / 2 + reagentTable('FeS2',:).n / 2 + reagentTable('Fe7S8',:).n / 2;
    m_S2_labile = n_S2_labile * (M_S * 2);
    labileSulphurFraction = m_S2_labile/100;
end