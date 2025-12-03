class UGravityBikeSplineDriverCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -90;

	UGravityBikeSplineDriverComponent DriverComp;
	UPlayerDamageScreenEffectComponent DamageScreenEffectComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeSplineDriverComponent::Get(Player);
		DamageScreenEffectComp = UPlayerDamageScreenEffectComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DriverComp.SpawnGravityBike();

		DamageScreenEffectComp.bAllowInFullScreen.Apply(true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DamageScreenEffectComp.bAllowInFullScreen.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Player.Mesh.CanRequestLocomotion())
            return;

        Player.Mesh.RequestLocomotion(GravityBikeSpline::GravityBikeSplinePlayerFeature, this);
	}
}