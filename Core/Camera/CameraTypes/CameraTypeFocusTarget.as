
/**
 * 
 */
UCLASS(NotBlueprintable)
class UFocusTargetCamera : UHazeCameraComponent
{
	default CameraUpdaterType = UCameraFocusTargetUpdater;
	default bHasKeepInViewSettings = true;
}

/**
 * 
 */
#if EDITOR
class UKeepInViewCameraVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UFocusTargetCamera;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto Camera = Cast<UFocusTargetCamera>(Component);
		Camera.VisualizeCameraEditorPreviewLocation(this);
	}
}
#endif

/**
 * 
 */
struct FCameraFocusTargetData
{
	AVolume ConstraintVolume = nullptr;
	
	protected float AspectRatio = -1;
	protected float MatchInitialVelocityFactor = -1;
	protected FVector UserVelocity = FVector::ZeroVector;

	protected FVector LocalConstrainCenter = FVector::ZeroVector;
	protected FVector AxisFreedomFactor = FVector::OneVector;
		
	void Init(const UHazeCameraUserComponent HazeUser, AVolume InConstraintVolume = nullptr, float MatchVelocityFactor = -1)
	{
		UserVelocity = HazeUser.ViewVelocity;
		AspectRatio = GetViewAspectRatioInternal(HazeUser);
		MatchInitialVelocityFactor = MatchVelocityFactor;
		ConstraintVolume = InConstraintVolume;
		devCheck(!Math::IsNaN(AspectRatio));
	}

	void SetAxisFreedomFactor(FVector Factor, FVector FreedomCenter, const UHazeCameraComponent Camera)
	{
		AxisFreedomFactor = Factor;
				
		const FTransform CameraTransform = Camera.GetWorldTransform();
		LocalConstrainCenter = CameraTransform.InverseTransformVector(FreedomCenter);
	}

	private float GetViewAspectRatioInternal(const UHazeCameraUserComponent User) const
	{
		AHazePlayerCharacter PlayerUser = Cast<AHazePlayerCharacter>(User.Owner);
		if (PlayerUser == nullptr)
			return (8.0 / 9.0);

        FVector2D Resolution = SceneView::GetPlayerViewResolution(PlayerUser);
		if(SceneView::GetFullScreenPlayer() == PlayerUser.OtherPlayer)
        	Resolution = SceneView::GetPlayerViewResolution(PlayerUser.OtherPlayer);

		if (Resolution.ContainsNaN())
			return NAN_flt;

		return Resolution.X / Math::Max(1.0, Resolution.Y);
	}

	void ApplyMatchVelocityToLocation(float Duration, FHazeAcceleratedVector& Location) const
	{
		if (MatchInitialVelocityFactor > 0.0)
		{
			// Lag behind at start, but with appropriate velocity
			Location.Value -= (UserVelocity * (Duration * 0.5 * MatchInitialVelocityFactor));			
			Location.Velocity = UserVelocity * MatchInitialVelocityFactor;
		}
	} 

	void GetTargetLocation(
		FTransform CameraTransform, 
		FCameraActiveSettings CameraSettings,
		FFocusTargets FocusTargets,
		FFocusTargets PrimaryTargets,
		FVector& Out) const
    {	
		if(FocusTargets.Targets.Num() == 0)
			return;

		float VerticalFOV = CameraSettings.FOV;
        float HorizontalFOV = CameraSettings.FOV;
		GetFOVs(CameraSettings.FOV, VerticalFOV, HorizontalFOV);

        TArray<FVector> FocusLocations;
        for (const auto& FocusTarget : FocusTargets.Targets)
        {
			FocusLocations.Add(CameraTransform.InverseTransformPosition(FocusTarget.Location));
        }

        // Find the horizontal and vertical intersections of fov lines through rightmost/leftmost and highest/lowest focus points.
        // This is where camera needs to be to show all focii
        FVector2D HorizontalIntersection = GetIdealCameraLocation(FocusLocations, HorizontalFOV, ECameraFocusTargetOrientation::Horizontal);
        FVector2D VerticalIntersection = GetIdealCameraLocation(FocusLocations, VerticalFOV, ECameraFocusTargetOrientation::Vertical);

        // Combine the horizontal and vertical intersections to get 3D intersection in camera space 
        // Note that we want the location furthest back, i.e. lowest X
        FVector Intersection;
        Intersection.X = Math::Min(HorizontalIntersection.X, VerticalIntersection.X);
        Intersection.Y = HorizontalIntersection.Y;
        Intersection.Z = VerticalIntersection.Y;

        // Find reference distance for min/max clamps
		const auto& KeepInViewCameraSettings = CameraSettings.KeepInView;
		float ClampedBufferDistance = Math::Min(KeepInViewCameraSettings.BufferDistance, KeepInViewCameraSettings.MaxDistance); // Buffer distance is not meaningful if greater than max
        float MinWithBuffer = KeepInViewCameraSettings.MinDistance - ClampedBufferDistance;
        float MaxWithBuffer = KeepInViewCameraSettings.MaxDistance - ClampedBufferDistance;
        float FocusDistance = BIG_NUMBER;

        if (PrimaryTargets.Num() > 0)
        {
			FVector PrimaryFocusLoc = FVector::ZeroVector;
			for (const auto& FocusTarget : PrimaryTargets.Targets)
       		{
				PrimaryFocusLoc += CameraTransform.InverseTransformPosition(FocusTarget.Location);
			}

            // Always use distance to primary 
			PrimaryFocusLoc /= PrimaryTargets.Num();
            FocusDistance = PrimaryFocusLoc.X - Intersection.X;

            // Make sure primary target is within view even when max distance clamp is applied
            if (FocusDistance > MaxWithBuffer)
            {
                FVector MaxDistanceClampedIntersection = Intersection;
                MaxDistanceClampedIntersection.X -= MaxWithBuffer - FocusDistance; 
                Intersection.Y = KeepLocationWithinView(PrimaryFocusLoc, MaxDistanceClampedIntersection, HorizontalFOV, ECameraFocusTargetOrientation::Horizontal);
                Intersection.Z = KeepLocationWithinView(PrimaryFocusLoc, MaxDistanceClampedIntersection, VerticalFOV, ECameraFocusTargetOrientation::Vertical);
            }
        }
        else
        {
            // No primary, use the closest focus point
            for (FVector FocusLoc : FocusLocations)
            {
                float Distance = FocusLoc.X - Intersection.X;
                FocusDistance = Math::Min(FocusDistance, Distance); 
            }
        }

        // Clamp to min/max distances (including buffer)
        if (FocusDistance > MaxWithBuffer)
            Intersection.X -= MaxWithBuffer - FocusDistance;
        else if (FocusDistance < MinWithBuffer)
            Intersection.X -= MinWithBuffer - FocusDistance;

        // Apply buffer distance
        Intersection.X -= ClampedBufferDistance;

		Intersection.X = Math::Lerp(LocalConstrainCenter.X, Intersection.X, AxisFreedomFactor.X);
        Intersection.Y = Math::Lerp(LocalConstrainCenter.Y, Intersection.Y, AxisFreedomFactor.Y);
        Intersection.Z = Math::Lerp(LocalConstrainCenter.Z, Intersection.Z, AxisFreedomFactor.Z);

		Out = CameraTransform.TransformPosition(Intersection);
		if (ConstraintVolume != nullptr)
		{
			// Keep camera within volume
			FVector ToTarget = (Out - CameraTransform.Location);
			if (!ToTarget.IsNearlyZero())
			{
				FVector ConstrainedOut = ConstraintVolume.FindClosestPoint(Out);
				if (!ConstrainedOut.Equals(FVector(BIG_NUMBER)))
				{
					Out = ConstrainedOut;
				}
			}
		}
    }

	// Calculate what 2D Y value is needed to keep given location within view when X is fixed.
    private float KeepLocationWithinView(const FVector& KeepInViewLoc, const FVector& ViewLocation, float FieldOfView, ECameraFocusTargetOrientation Orientation) const
    {
        FVector2D KeepInViewLoc2D = GetVectorIn2DOrientation(KeepInViewLoc, Orientation);
        FVector2D ViewLoc2D = GetVectorIn2DOrientation(ViewLocation, Orientation);
        
        float HalfFOV = FieldOfView * 0.5;
        float SinHalfFOV = 0.0;
        float CosHalfFOV = 1.0;
        Math::SinCos(SinHalfFOV, CosHalfFOV, Math::DegreesToRadians(HalfFOV));
        FVector2D LowFOV = FVector2D(CosHalfFOV, -SinHalfFOV);
        FVector2D HighFOV = FVector2D(CosHalfFOV, SinHalfFOV);
        FVector2D SideDir = FVector2D(0.0, -1.0); // Since FOV directions are away from intersection
        
        // Find intersections between lines in FOV direction starting at location to keep in view and the 
        // line fixed X (0,1) direction line through the view location
        float LowFOVIntersectionDistance = GetIntersectionDistance(ViewLoc2D, SideDir, KeepInViewLoc2D, LowFOV); 
        float HighFOVIntersectionDistance = GetIntersectionDistance(ViewLoc2D, SideDir, KeepInViewLoc2D, HighFOV); 

        // If lines intersect at either side of view location, it is already within view and can be returned as is.
        if (Math::Sign(LowFOVIntersectionDistance) != Math::Sign(HighFOVIntersectionDistance))
            return ViewLoc2D.Y;

        // If lines intersect on the low side of the view location, low fov intersection will be closest
        if (LowFOVIntersectionDistance < 0)
            return ViewLoc2D.Y + LowFOVIntersectionDistance;

        // Lines intersect on the high side of the view location, high fov intersection will be closest
        return ViewLoc2D.Y + HighFOVIntersectionDistance;  
    }

	private FVector2D GetIdealCameraLocation(TArray<FVector> FocusLocations, float FieldOfView, ECameraFocusTargetOrientation Orientation) const
    {
        // Find highest(rightmost) and lowest(leftmost) focus locations. Note that these may be the same location.
        FVector2D LowestLocation = GetVectorIn2DOrientation(FocusLocations[0], Orientation);
        FVector2D HighestLocation = GetVectorIn2DOrientation(FocusLocations[0], Orientation);

        float HalfFOV = FieldOfView * 0.5;
        float SinHalfFOV = 0.0;
        float CosHalfFOV = 1.0;
        Math::SinCos(SinHalfFOV, CosHalfFOV, Math::DegreesToRadians(HalfFOV));

        FVector2D LowOrthogonal = FVector2D(SinHalfFOV, -CosHalfFOV);
        FVector2D HighOrthogonal = FVector2D(SinHalfFOV, CosHalfFOV);
        for (int32 i = 1; i < FocusLocations.Num(); i++)
        {
            FVector2D FocusLoc2D = GetVectorIn2DOrientation(FocusLocations[i], Orientation);   
                     
            FVector2D ToHighestLocation = HighestLocation - FocusLoc2D;                        
            if (ToHighestLocation.DotProduct(LowOrthogonal) > 0)                
                HighestLocation = FocusLoc2D;
       
            FVector2D ToLowestLocation = LowestLocation - FocusLoc2D;
            if (ToLowestLocation.DotProduct(HighOrthogonal) > 0)
                LowestLocation = FocusLoc2D;
        }

        // Find intersection between lines from highest location in high fov direction and lowest with low fov direction.
        FVector2D LowFOV = FVector2D(CosHalfFOV, -SinHalfFOV);
        FVector2D HighFOV = FVector2D(CosHalfFOV, SinHalfFOV);

		// HACK which only handles axis freedom factor (1,0,0), i.e. sliding in and out, but no orthogonal movement.
		if (AxisFreedomFactor.Equals(FVector(1.0, 0.0, 0.0)))
		{
			// Find intersection with line straight forward from origin and return highest intersection
			float LowIntersectionDistance = GetIntersectionDistance(FVector2D(0.0, 0.0), FVector2D(1.0, 0.0), LowestLocation, LowFOV);
			float HighIntersectionDistance = GetIntersectionDistance(FVector2D(0.0, 0.0), FVector2D(1.0, 0.0), HighestLocation, HighFOV);
			return FVector2D(Math::Min(-LowIntersectionDistance, -HighIntersectionDistance), 0.0);
		}

        float HighDistanceToIntersection = GetIntersectionDistance(HighestLocation, HighFOV, LowestLocation, LowFOV);
        return HighestLocation - HighFOV * HighDistanceToIntersection; // Move backwards along FOV direction since it's away from intersection
    }

	private FVector2D GetVectorIn2DOrientation(FVector Vector, ECameraFocusTargetOrientation Orientation) const
    {
        if (Orientation == ECameraFocusTargetOrientation::Horizontal)
            return FVector2D(Vector.X, Vector.Y);
        else
            return FVector2D(Vector.X, Vector.Z);
    } 

	// Find distance (can be negative) from start to intersection by other line starting at given locations with given directions.
    // Note that this assumes the directions are normalized and non-parallel 
    private float GetIntersectionDistance(const FVector2D& Start, const FVector2D& Dir, const FVector2D& OtherStart, const FVector2D& OtherDir) const
    {
        return (Cross2D(Start, OtherDir) - Cross2D(OtherStart, OtherDir)) / Cross2D(Dir, OtherDir);
    }

	private float Cross2D(FVector2D A, FVector2D B) const
    {
        return (A.X * B.Y) - (A.Y * B.X);
    } 

	private void GetFOVs(float FOV, float& VerticalFOV, float& HorizontalFOV) const
	{
		float ValidAspectRatio = 8.0 / 9.0;
		if(AspectRatio > KINDA_SMALL_NUMBER)
			ValidAspectRatio = AspectRatio;

        VerticalFOV = Math::Clamp(FOV, 5.0, 89.0);
        HorizontalFOV = Math::Clamp(Math::RadiansToDegrees(2 * Math::Atan(Math::Tan(Math::DegreesToRadians(FOV * 0.5)) * ValidAspectRatio)), 5.0, 179.0);
	}
}

/**
 * 
 */
struct FCameraFocusTargetUserData
{
    FHazeAcceleratedVector PreviousViewLocation; 
	FHazeAcceleratedQuat PreviousViewRotation;
}

/**
 * 
 */
enum ECameraFocusTargetOrientation
{
	Horizontal,
	Vertical
}


/**
 * A camera updater that will move and/or rotate the camera to keep the focus target(s) in view
 */
UCLASS(NotBlueprintable)
class UCameraFocusTargetUpdater : UHazeCameraUpdater
{
	FCameraFocusTargetUserData UserData;
	FCameraFocusTargetData UpdaterSettings;

	// These are not part of the settings
	// because they should always be passed into the functions
	float RotationDuration = -1;
	float LocationDuration = -1;

	FFocusTargets FocusTargets;
	FFocusTargets PrimaryTargets;

	void UseFocusLocation(float Duration = 0)
	{
		LocationDuration = Math::Max(Duration, 0);
	}

	void UseFocusRotation(float Duration = 0)
	{
		RotationDuration = Math::Max(Duration, 0);
	}

	UFUNCTION(BlueprintOverride)
	protected void Copy(const UHazeCameraUpdater SourceBase)
	{
		auto Source = Cast<UCameraFocusTargetUpdater>(SourceBase);

		UserData = Source.UserData;
		UpdaterSettings = Source.UpdaterSettings;
		RotationDuration = Source.RotationDuration;
		LocationDuration = Source.LocationDuration;
		FocusTargets = Source.FocusTargets;
		PrimaryTargets = Source.PrimaryTargets;
	}

	UFUNCTION(BlueprintOverride)
	protected void PrepareForUser()
	{
		// Start every frame with clean settings
		// so the camera can just apply the settings it want this frame
		UpdaterSettings = FCameraFocusTargetData();
		FocusTargets = FFocusTargets();
		PrimaryTargets = FFocusTargets();
		RotationDuration = -1;
		LocationDuration = -1;
	}

	UFUNCTION(BlueprintOverride)
	protected void OnCameraSnap(FHazeCameraTransform& CameraTransformTarget)
	{
		const FTransform TargetView = CameraTransformTarget.ViewTransform;

		FVector NewTargetLocation = TargetView.Location;
		if(LocationDuration >= 0)
		{
			UpdaterSettings.GetTargetLocation(TargetView, CameraSettings, FocusTargets, PrimaryTargets, NewTargetLocation);
		}

		FQuat NewTargetRotation = TargetView.Rotation;
		if(RotationDuration >= 0)
		{
			FocusTargets.GetFocusRotation(NewTargetLocation, NewTargetRotation);
			NewTargetRotation = CameraSettings.KeepInView.LookOffset.Quaternion() * WorldToLocalQuat(NewTargetRotation);
			NewTargetRotation = ClampLocalQuat(NewTargetRotation);
			NewTargetRotation = LocalToWorldQuat(NewTargetRotation);
		}
		else
		{
			NewTargetRotation = ClampWorldQuat(NewTargetRotation);
		}

		UserData.PreviousViewRotation.SnapTo(NewTargetRotation);
		UserData.PreviousViewLocation.SnapTo(NewTargetLocation);

		// Try to match accelerated location and velocity with average focus velocity
		if (LocationDuration >= 0)
			UpdaterSettings.ApplyMatchVelocityToLocation(LocationDuration, UserData.PreviousViewLocation);
		
		CameraTransformTarget.ViewLocation = UserData.PreviousViewLocation.Value;
	}

	UFUNCTION(BlueprintOverride)
	protected void OnCameraUpdate(float DeltaTime, FHazeCameraTransform& CameraTransformTarget)
	{
		const FTransform TargetView = CameraTransformTarget.ViewTransform;

		// Should this camera update its position
		if(LocationDuration >= 0)
		{
			FVector NewTargetLocation = TargetView.Location;
			if(FocusTargets.Num() > 0)
			{
				UpdaterSettings.GetTargetLocation(TargetView, CameraSettings, FocusTargets, PrimaryTargets, NewTargetLocation);
				
				// Accelerate to target location
				if(LocationDuration > 0)
					UserData.PreviousViewLocation.AccelerateTo(NewTargetLocation, LocationDuration, DeltaTime);
				else
					UserData.PreviousViewLocation.SnapTo(NewTargetLocation);
			}
			else
			{	
				// No active targets, slide to a stop
				float Dampening = 5.0 / Math::Max(0.1, LocationDuration);
				UserData.PreviousViewLocation.Velocity -= UserData.PreviousViewLocation.Velocity * Math::Min(1.0, Dampening * DeltaTime);
				UserData.PreviousViewLocation.Value += UserData.PreviousViewLocation.Velocity * DeltaTime;
			}

			CameraTransformTarget.ViewLocation = UserData.PreviousViewLocation.Value;
		}
		// If not, always update the previous location
		else
		{
			UserData.PreviousViewLocation.SnapTo(TargetView.Location);
		}

		// Should this camera update its rotation
		if(RotationDuration >= 0)
		{
			FQuat NewTargetRotation = TargetView.Rotation;
			FocusTargets.GetFocusRotation(CameraTransformTarget.ViewLocation, NewTargetRotation);

			NewTargetRotation = CameraSettings.KeepInView.LookOffset.Quaternion() * WorldToLocalQuat(NewTargetRotation);
			NewTargetRotation = ClampLocalQuat(NewTargetRotation);
			NewTargetRotation = LocalToWorldQuat(NewTargetRotation);

			if(RotationDuration > 0)
				UserData.PreviousViewRotation.AccelerateTo(NewTargetRotation, RotationDuration, DeltaTime);
			else
				UserData.PreviousViewRotation.SnapTo(NewTargetRotation);
		
			CameraTransformTarget.ViewRotation = UserData.PreviousViewRotation.Value.Rotator();
		}
		// If not, always update the previous rotation
		else
		{
			UserData.PreviousViewRotation.SnapTo(TargetView.Rotation);
		}
	}
}
