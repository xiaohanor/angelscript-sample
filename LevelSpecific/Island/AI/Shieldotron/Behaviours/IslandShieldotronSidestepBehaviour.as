
class UIslandShieldotronSidestepBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	//default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UPathfollowingSettings PathingSettings;

	UIslandShieldotronSettings Settings;

	bool bStrafeLeft = false;
	bool bTriedBothDirections = false;
	float Radius;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		Settings = UIslandShieldotronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!TargetComp.HasValidTarget())
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
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bStrafeLeft = !bStrafeLeft;
		Owner.BlockCapabilities(n"MortarAttack", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(GetCooldownDuration());
		Owner.UnblockCapabilities(n"MortarAttack", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector Side = Owner.ActorRightVector * 100;
		if (bStrafeLeft)
			Side *= -1.0;
		float CircleDist = OwnLoc.Distance(TargetLoc);
		FVector CircleOffset = (OwnLoc + Side - TargetLoc).GetClampedToMaxSize(CircleDist);
		FVector StrafeDest = TargetLoc + CircleOffset;

		DestinationComp.MoveTowards(StrafeDest, Settings.SidestepStrafeSpeed);

		DestinationComp.RotateTowards(TargetComp.Target);
		
		if (DoChangeDirection(StrafeDest))
			DeactivateBehaviour();

		if (ActiveDuration > 1.0)
			DeactivateBehaviour();
	}

	float GetCooldownDuration()
	{
		float CooldownDuration = Math::RandRange(4.0, 6.0);
		FVector FromTarget = (Owner.ActorCenterLocation - TargetComp.Target.ActorCenterLocation);
		FromTarget.Z = 0.0;
		FromTarget.Normalize();
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (Player != nullptr)
		{
			FVector ViewYawDir = FRotator(0.0, Player.ViewRotation.Yaw, 0.0).Vector();
			//Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + ViewYawDir * 300, Duration = 2.0);
			//Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + FromTarget * 300, Duration = 2.0, LineColor = FLinearColor::Red);			
			//if (ViewYawDir.DotProduct(FromTarget) < 0.707) // 45 degrees
			float Angle = 10;
			if (ViewYawDir.DotProduct(FromTarget) < Math::Cos(Math::DegreesToRadians(Angle)))
				return CooldownDuration;
			//Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + FromTarget * 300, Duration = 2.0, LineColor = FLinearColor::Green);
		}

		return CooldownDuration * 0.25;
	}
	
	private bool DoChangeDirection(FVector StrafeDest)
	{
		if(DestinationComp.MoveFailed())
			return true;

		return false;
	}

	private bool CanMove(FVector StrafeDest)
	{

		FVector StrafeDestNavMesh;
		FVector PathStrafeDest = StrafeDest + (StrafeDest - Owner.ActorLocation).GetSafeNormal() * Radius * 4.0;
		if(!Pathfinding::FindNavmeshLocation(PathStrafeDest, 0.0, 100.0, StrafeDestNavMesh))
			return false;

		if(!Pathfinding::StraightPathExists(Owner.ActorLocation, StrafeDestNavMesh))
			return false;

		return true;
	}
	
}