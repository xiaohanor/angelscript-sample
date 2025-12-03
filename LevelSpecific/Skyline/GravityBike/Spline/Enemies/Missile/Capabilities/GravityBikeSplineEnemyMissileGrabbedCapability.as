struct FGravityBikeSplineEnemyMissileGrabbedActivateParams
{
	FGravityBikeWhipGrabMoveData GrabMoveData;
	AHazePlayerCharacter GrabbedByPlayer;
};

struct FGravityBikeSplineEnemyMissileGrabbedDeactivateParams
{
	UGravityBikeWhipComponent WhipComp;
};

class UGravityBikeSplineEnemyMissileGrabbedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 50;

	AGravityBikeSplineEnemyMissile Missile;
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Missile = Cast<AGravityBikeSplineEnemyMissile>(Owner);
		GrabTargetComp = UGravityBikeWhipGrabTargetComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeSplineEnemyMissileGrabbedActivateParams& Params) const
	{
		if(!GrabTargetComp.IsGrabbed())
			return false;

		Params.GrabMoveData = GrabTargetComp.GrabMoveData;
		Params.GrabbedByPlayer = GrabTargetComp.GetWhipComponent().Player;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeSplineEnemyMissileGrabbedDeactivateParams& Params) const
	{
		if(!GrabTargetComp.IsGrabbed())
		{
			Params.WhipComp = GrabTargetComp.GetWhipComponent();
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeSplineEnemyMissileGrabbedActivateParams Params)
	{
		GrabTargetComp.GrabMoveData = Params.GrabMoveData;
		
		FGravityBikeSplineEnemyMissileOnGrabbedEventData EventData;
		EventData.GrabbedByPlayer = Params.GrabbedByPlayer;
		UGravityBikeSplineEnemyMissileEventHandler::Trigger_OnGrabbed(Missile, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineEnemyMissileGrabbedDeactivateParams Params)
	{
		if(Params.WhipComp != nullptr)
		{
			FGravityBikeSplineEnemyMissileOnDroppedEventData EventData;
			EventData.DroppedByPlayer = Params.WhipComp.Player;
			UGravityBikeSplineEnemyMissileEventHandler::Trigger_OnDropped(Missile, EventData);
		}

		Missile.MovementData.AccMoveSpeed.SnapTo(Missile.ActorVelocity.DotProduct(Missile.ActorForwardVector));

		Missile.ChangeState(EGravityBikeSplineEnemyMissileState::Dropped);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Missile.MovementData.Prepare(Missile.ActorLocation, Missile.ActorQuat, this);

		const FVector Location = GrabTargetComp.GrabMoveData.GetWorldLocation();

		FVector Delta = Location - Missile.ActorLocation;
		FVector Velocity = Delta / DeltaTime;

		Missile.SetActorVelocity(Velocity);
		Missile.SetActorLocation(Location);
		
		if(GrabTargetComp.HasThrowTarget())
		{
			FQuat TargetRotation = FQuat::MakeFromXZ(GrabTargetComp.GetThrowTargetWorldLocation() - Missile.ActorLocation, GravityBikeSpline::GetGlobalUp());
			FQuat Rotation = Math::QInterpConstantTo(Missile.ActorQuat, TargetRotation, DeltaTime, 5);
			//Rotation = Rotation * FQuat(FVector::ForwardVector, Time::GameTimeSeconds * 0.01);
			Missile.SetActorRotation(Rotation);
		}
		else
		{
			FQuat TargetRotation = FQuat::MakeFromXZ(Missile.GetSplineTransform().Rotation.ForwardVector, GravityBikeSpline::GetGlobalUp());
			const FQuat Rotation = Math::QInterpConstantTo(Missile.ActorQuat, TargetRotation, DeltaTime, 5);
			Missile.SetActorRotation(Rotation);
		}

		Missile.MovementData.ApplyHandled();
	}
};