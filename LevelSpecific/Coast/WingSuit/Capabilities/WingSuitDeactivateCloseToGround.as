
class UWingSuitDeactivateCloseToGround : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Wingsuit");
	default CapabilityTags.Add(n"WingsuitMovement");

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"Wingsuit";
	
	UPlayerMovementComponent MoveComp;
	UWingSuitPlayerComponent WingSuitComp;
	UWingSuitSettings Settings;

	const float AnimationTransitionDuration = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Settings = UWingSuitSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WingSuitComp.bWingsuitActive)
			return false;

		if(Settings.GroundDistanceDeactivation <= KINDA_SMALL_NUMBER)
			return false;

		auto GroundTraceSettings = Trace::InitFromMovementComponent(MoveComp);
		GroundTraceSettings.UseLine();
		//GroundTraceSettings.DebugDrawOneFrame();

		FVector TraceFrom = Player.ActorLocation;
		FVector TraceTo = TraceFrom;
		TraceTo -= FVector::UpVector * (MoveComp.GetCollisionShape().Shape.GetSphereRadius() + Settings.GroundDistanceDeactivation);
		auto GroundHit = GroundTraceSettings.QueryTraceSingle(TraceFrom, TraceTo);
		if(!GroundHit.bBlockingHit)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration >= AnimationTransitionDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AWingsuitManager Manager = WingSuitComp.Manager;
	
		auto PlayerComp = UWingSuitPlayerComponent::Get(Player);
		PlayerComp.DestroyWingSuit();
		Player.ResetMovement();

		// Broadcast the landing after we removed the wingsuit from the player
		Manager.OnWingSuitLanded.Broadcast(Player);
		WingSuitComp.AnimData.bIsLandingOnGround = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WingSuitComp.AnimData.bIsLandingOnGround = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Player.Mesh.CanRequestLocomotion())
		{
			Player.Mesh.RequestLocomotion(n"WingSuit", this);
		}
	}
};