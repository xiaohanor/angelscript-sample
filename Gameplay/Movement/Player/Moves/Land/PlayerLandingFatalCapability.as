
class UPlayerLandingFatalCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"Landing");

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 50;

	UPlayerMovementComponent MoveComp;
	UPlayerLandingComponent LandingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		LandingComp = UPlayerLandingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PlayerLanding::CVar_MovementAllowFallDamage.GetInt() == 0)
			return false;

		if (MoveComp.IsInAir())
			return false;

		if (!MoveComp.WasFalling())
			return false;

		if (LandingComp.InstigatedFatalLandingMode.Get() == EPlayerLandingMode::Avoid)
			return false;
		if (LandingComp.InstigatedFatalLandingMode.Get() == EPlayerLandingMode::Force)
			return true;

		if(LandingComp.HasBlockedFallDamage())
			return false;

		const float LandSpeed = -MoveComp.WorldUp.DotProduct(MoveComp.FallingData.EndVelocity);
		if (LandSpeed < LandingComp.Settings.Fatal.Speed)
			return false;
		
		const FVector ToLandLocation = MoveComp.FallingData.EndLocation - MoveComp.FallingData.StartLocation;
		const float Distance = Math::Abs(ToLandLocation.DotProduct(MoveComp.WorldUp));
		if (Distance < LandingComp.Settings.Fatal.Distance)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
#if !RELEASE
		const float LandSpeed = -MoveComp.WorldUp.DotProduct(MoveComp.FallingData.EndVelocity);
		TEMPORAL_LOG(this).Value("Land Speed", LandSpeed);

		const FVector ToLandLocation = MoveComp.FallingData.EndLocation - MoveComp.FallingData.StartLocation;
		const float FallDistance = Math::Abs(ToLandLocation.DotProduct(MoveComp.WorldUp));
		TEMPORAL_LOG(this).Value("Fall Distance", FallDistance);

		if (IsDebugActive())
		{
			Debug::DrawDebugSphere(MoveComp.FallingData.StartLocation, 10, 16, FLinearColor::Green, 1.0, 6.0);
			Debug::DrawDebugSphere(MoveComp.FallingData.EndLocation, 10, 16, FLinearColor::Red, 1.0, 6.0);
			Debug::DrawDebugLine(MoveComp.FallingData.StartLocation, MoveComp.FallingData.EndLocation, FLinearColor::Gray, 2.0, 6.0);
		}
#endif

		// Player.TriggerEffectEvent(n"PlayerLandFatal.Activated"); // UNKNOWN EFFECT EVENT NAMESPACE
		Player.KillPlayer(DeathEffect = LandingComp.DeathEffect);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Player.TriggerEffectEvent(n"PlayerLandFatal.Deactivated"); // UNKNOWN EFFECT EVENT NAMESPACE
	}
}