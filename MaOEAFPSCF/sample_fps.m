function Y = sample_fps(D, k)
    n = size(D, 1);
    
    % Initialize the set of selected points.
    Y = zeros(k, 1);
    
    % Choose the first point randomly or based on some criteria.
    Y(1) = randi(n);  % Randomly select the first point
    
    % Compute the distance matrix if not already given.
    if isstruct(D)
        % Assuming D has a distance matrix as a field.
        dist_matrix = D.distances;  % Replace with the correct field name.
    else
        % If D is a simple distance matrix.
        dist_matrix = D;
    end
    
    % Initialize the minimum distances to infinity.
    min_distances = inf(1, n);
    
    % Update the minimum distance for the first selected point.
    min_distances(Y(1)) = 0;
    
    for i = 2:k
        % Find the index of the farthest point from the current set.
        [~, idx] = max(min_distances);
        
        % Add the farthest point to the result set.
        Y(i) = idx;
        
        % Update the minimum distances for all points.
        min_distances = min(min_distances, dist_matrix(:, idx));
    end
    
    % Sort the indices if needed.
    Y = sort(Y);
    
    % Return the final set of indices.
end