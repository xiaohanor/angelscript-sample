
class USanctuaryWeeperStrafeAdvanceBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	bool bStrafeLeft = false;
	bool bTriedBothDirections = false;
	bool bIlluminated;
	
	AActor LightSource;
	USanctuaryWeeperSettings Settings;

	float Radius;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		auto ArtifactResponseComp = USanctuaryWeeperArtifactResponseComponent::Get(Owner);
		ArtifactResponseComp.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		ArtifactResponseComp.OnStopIlluminated.AddUFunction(this, n"OnStopIlluminated");
		Settings = USanctuaryWeeperSettings::GetSettings(Owner);

		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
	}

	UFUNCTION()
	private void OnIlluminated(ASanctuaryWeeperArtifact Artifact)
	{
		bIlluminated = true;
		LightSource = Artifact;
	}

	UFUNCTION()
	private void OnStopIlluminated(ASanctuaryWeeperArtifact Artifact)
	{
		bIlluminated = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if(!bIlluminated)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if(!bIlluminated)
			return true;

		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		FVector Origin = LightSource.ActorLocation;
		FVector Direction = LightSource.ActorForwardVector;
		FVector ToLightCenter = Math::ProjectPositionOnInfiniteLine(Origin, Direction, Owner.ActorLocation) - Owner.ActorLocation;		

		if(ToLightCenter.DotProduct(Owner.ActorRightVector) > 0)
			bStrafeLeft = true;
		else
			bStrafeLeft = false;
			
		bTriedBothDirections = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector Side = Owner.ActorUpVector.CrossProduct(TargetLoc - OwnLoc);
		Side = Side.GetClampedToSize(DestinationComp.MinMoveDistance, DestinationComp.MinMoveDistance + 80.0);
		if (bStrafeLeft)
			Side *= -1.0;
		float CircleDist = Math::Max(Settings.CircleStrafeMinRange, OwnLoc.Distance(TargetLoc) - 100.0);
		FVector CircleOffset = (OwnLoc + Side - TargetLoc).GetClampedToMaxSize(CircleDist);
		FVector StrafeDest = TargetLoc + CircleOffset;
		DestinationComp.MoveTowards(StrafeDest, Settings.CircleStrafeSpeed);

		DestinationComp.RotateTowards(TargetComp.Target);
		

		if (DoChangeDirection(StrafeDest))
		{
			if (bTriedBothDirections)
				Cooldown.Set(2.0); // Stuck, try again in a while
			bStrafeLeft = !bStrafeLeft;
			bTriedBothDirections = true;
		}
	}

	private bool DoChangeDirection(FVector StrafeDest)
	{
		if(DestinationComp.MoveFailed())
			return true;

		FVector StrafeDestNavMesh;
		FVector PathStrafeDest = StrafeDest + (StrafeDest - Owner.ActorLocation).GetSafeNormal() * Radius;
		if(!Pathfinding::FindNavmeshLocation(PathStrafeDest, 0.0, 100.0, StrafeDestNavMesh))
			return true;

		if(!Pathfinding::StraightPathExists(Owner.ActorLocation, StrafeDestNavMesh))
			return true;

		return false;
	}
}
