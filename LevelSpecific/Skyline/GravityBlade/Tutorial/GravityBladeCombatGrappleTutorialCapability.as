class AGravityBladeCombatGrappleTutorialLocation : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent RootComp;
}

class UGravityBladeCombatGrappleTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GravityBladeTutorial");
	default CapabilityTags.Add(n"Tutorial");

	UGravityBladeCombatUserComponent GravityBladeCombatUserComponent;
	UGravityBladeGrappleUserComponent GravityBladeGrappleUserComponent;
	UGravityBladeTutorialComponent GravityBladeTutorialComponent;
	UPlayerAimingComponent PlayerAimingComponent;
	UGravityBladeGrappleComponent TargetComp;
	USceneComponent AttachComponent;
	AGravityBladeCombatGrappleTutorialLocation StaticLocationActor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBladeCombatUserComponent = UGravityBladeCombatUserComponent::Get(Player);
		GravityBladeGrappleUserComponent = UGravityBladeGrappleUserComponent::Get(Player);
		GravityBladeTutorialComponent = UGravityBladeTutorialComponent::Get(Player);
		PlayerAimingComponent = UPlayerAimingComponent::Get(Player);
		StaticLocationActor = AGravityBladeCombatGrappleTutorialLocation::Spawn();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (GravityBladeTutorialComponent.bCombatGrappleTutorialComplete)
			return false;

		if (!GravityBladeGrappleUserComponent.AimGrappleData.IsValid())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GravityBladeTutorialComponent.bCombatGrappleTutorialComplete)
			return true;

		if (!GravityBladeGrappleUserComponent.AimGrappleData.IsValid())
			return true;

		if (TargetComp != GravityBladeGrappleUserComponent.AimGrappleData.GrappleComponent)
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetComp = GravityBladeGrappleUserComponent.AimGrappleData.GrappleComponent;
		AttachComponent = TargetComp.Owner.RootComponent;
		StaticLocationActor.ActorLocation = TargetComp.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Offset = 400;
		if(GravityBladeTutorialComponent.CombatGrappleTutorialOffsetOverride.IsSet())
			Offset = GravityBladeTutorialComponent.CombatGrappleTutorialOffsetOverride.Value;

		if(GravityBladeTutorialComponent.bCombatGrappleTutorialStaticLocation.Get(false))
			AttachComponent = StaticLocationActor.RootComp;

		Player.ShowTutorialPromptWorldSpace(GravityBladeTutorialComponent.PromptCombatGrapple, this, AttachComponent, FVector(0, 0, Offset), 0);
	}
}