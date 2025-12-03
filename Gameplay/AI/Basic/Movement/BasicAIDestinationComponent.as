
/**
 * 
 */
struct FHazeBasicAITarget
{
	private bool bIsValid = false;
	private AActor ActorTarget;
	private bool bUseWorldLocation = true;
	private FVector WorldLocation;

	FVector WorldOffset = FVector::ZeroVector;
	FVector LocalOffset = FVector::ZeroVector;

	FHazeBasicAITarget()
	{

	}

	FHazeBasicAITarget(AActor Actor)
	{
		bUseWorldLocation = false;
		ActorTarget = Actor;
		bIsValid = ActorTarget != nullptr;
	}

	FHazeBasicAITarget(FVector Location)
	{
		bUseWorldLocation = true;
		WorldLocation = Location;
		bIsValid = true;
	}

	FVector GetFocusLocation() const
	{
		FVector OutLocation = WorldLocation;

		if(!bUseWorldLocation && ActorTarget != nullptr)
		{
			auto HazeActor = Cast<AHazeActor>(ActorTarget);
			if(HazeActor != nullptr)
			{
				OutLocation = HazeActor.GetFocusLocation();
			}
			else
			{
				OutLocation = ActorTarget.ActorLocation;
			}
	
			OutLocation += ActorTarget.ActorRotation.RotateVector(LocalOffset);
		}

		OutLocation += WorldOffset;
		return OutLocation;
	}

	AActor GetTargetActor() const
	{
		return ActorTarget;
	}

	bool IsValid() const
	{
		return bIsValid;
	}
};

class UBasicAIDestinationComponent : UActorComponent
{
	UPROPERTY()
	UBasicAIMovementSettings DefaultMovementSettings;

	UPathfollowingSettings PathingSettings;

	// What we should be looking at. Reset every update, so behaviours need to continuously set this
	FHazeBasicAITarget Focus;

	// If set, we should move towards destination at this speed. Reset to zero every update, so behaviours need to continuously set this
	float Speed;

	// Where we are going (or were going if MovementSpeed is zero) 
	FVector Destination;

	// Additional acceleration from crowd avoidance etc. 
	FVector CustomAcceleration; 

	// Spline to follow, if any
	UHazeSplineComponent FollowSpline;
	bool bFollowSplineForwards = true;
	FSplinePosition FollowSplinePosition;

	bool bHasPerformedMovement = false;

	UPathfollowingMoveToComponent MoveToComp;
	UBasicAIAnimationComponent AnimComp;
	AHazeActor HazeOwner;
	bool bClearSettingsOnUpdate = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveToComp = UPathfollowingMoveToComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		HazeOwner = Cast<AHazeActor>(Owner);
		if (DefaultMovementSettings != nullptr)
			HazeOwner.ApplyDefaultSettings(DefaultMovementSettings);
		PathingSettings = UPathfollowingSettings::GetSettings(HazeOwner);
	}

	UFUNCTION()
	private void Reset()
	{
		Update();
	}

	bool HasDestination() const
	{
		return (Speed > 0.0);
	}

	void MoveTowards(FVector MoveDestination, float MoveSpeed)
	{
		this.Destination = MoveDestination;
		this.Speed = MoveSpeed;
		MoveToComp.MoveTo(MoveDestination, this);
	}

	void MoveTowardsIgnorePathfinding(FVector MoveDestination, float MoveSpeed)
	{
		this.Destination = MoveDestination;
		this.Speed = MoveSpeed;
		UPathfollowingSettings::SetIgnorePathfinding(HazeOwner, true, this, EHazeSettingsPriority::Override);
		bClearSettingsOnUpdate = true;	
	}

	void RotateTowards(FVector FocusLoc)
	{
		Focus = FHazeBasicAITarget(FocusLoc);
	}

	void RotateTowards(AHazeActor FocusActor)
	{
		Focus = FHazeBasicAITarget(FocusActor);
	}

	void RotateTowards(FHazeBasicAITarget FocusTarget)
	{
		Focus = FocusTarget;
	}

	void RotateInDirection(FVector Direction)
	{
		Focus = FHazeBasicAITarget(Cast<AHazeActor>(Owner).FocusLocation + Direction * 1000.0);
	}

	void MoveAlongSpline(UHazeSplineComponent Spline, float MoveSpeed, bool bForwards = true)
	{
		FollowSpline = Spline;
		Speed = MoveSpeed;
		bFollowSplineForwards = bForwards;
	}

	bool IsAtSplineEnd(UHazeSplineComponent Spline, float Threshold)
	{
		if (Spline == nullptr)
			return false;
		if (Spline != FollowSplinePosition.CurrentSpline)
			return false;
		if (bFollowSplineForwards && (FollowSplinePosition.CurrentSplineDistance < Spline.SplineLength - Threshold))
			return false;
		if (!bFollowSplineForwards && (FollowSplinePosition.CurrentSplineDistance > Threshold))
			return false;
		return true;
	}

	void AddCustomAcceleration(FVector Acceleration)
	{
		if (!ensure(!Acceleration.ContainsNaN()))
			return;
		CustomAcceleration += Acceleration;
	}

	void Update()
	{
		// Reset control values so we'll come to a stop when not continuously settings them.
		bHasPerformedMovement = false;
		Speed = 0.0;
		Focus = FHazeBasicAITarget();
		CustomAcceleration = FVector::ZeroVector;
		if (bClearSettingsOnUpdate)
		{
			HazeOwner.ClearSettingsByInstigator(this);
			bClearSettingsOnUpdate = false;
		}
		FollowSpline = nullptr;
	}

	void ReportStopping()
	{
		MoveToComp.StopMoveTo(this);
	}

	bool MoveSuccess()
	{
		return MoveToComp.WasSuccess(this);
	}

	bool MoveStopped()
	{
		return MoveToComp.GetStatus(this) == EPathfollowingMoveToStatus::Stopped;
	}

	bool MoveFailed()
	{
		return MoveToComp.WasFailure(this);
	}

	float GetMinMoveDistance() const property
	{
		return Math::Max(20.0, PathingSettings.AtDestinationRange);
	}

	void ForceLocation(FVector Location)
	{
		// Hack to set location for prototyping. TODO: Fix proper solution.
		Owner.SetActorLocation(Location);
	}
}