function [h_matte_m] = calcMatteHeightWithSkew(v_matte_m3, l_furnace_m, w_furnace_m, R_hearth_m, v_skew_m3)
    %Calculates matte height, taking into account circular skew
    %   Detailed explanation goes here
    h_skew_m = R_hearth_m - sqrt(R_hearth_m^2 - (w_furnace_m/2)^2); % constant since R_hearth_m and w_furnace_m are constants
    if v_matte_m3 >= v_skew_m3
        v_matte_above_skew_m3 = v_matte_m3 - v_skew_m3;
        h_matte_m = h_skew_m + v_matte_above_skew_m3/(l_furnace_m * w_furnace_m);
        return
    end

    % theta - sin(theta) = 2 A/R^2
    syms f(theta)
    f(theta) = theta - sin(theta) - 2 * (v_matte_m3 / l_furnace_m) / R_hearth_m ^2;
    thetaAns = vpasolve(f, theta, 0);
    h_matte_m = R_hearth_m * (1 - cos(thetaAns/2));
end

