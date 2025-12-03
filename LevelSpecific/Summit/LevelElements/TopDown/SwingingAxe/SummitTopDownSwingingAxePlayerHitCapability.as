struct FSummitTopDownSwingingAxePlayerHitActivationParams
{
	FVector AxeImpulse;
}

class USummitTopDownSwingingAxePlayerHitCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	USummitTopDownSwingingAxePlayerHitComponent AxeComp;
	UPlayerTeenDragonComponent DragonComp;
	URagdollComponent RagdollComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AxeComp = USummitTopDownSwingingAxePlayerHitComponent::Get(Player);
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		
		RagdollComp = URagdollComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitTopDownSwingingAxePlayerHitActivationParams& Params) const
	{
		if(DragonComp == nullptr)
			return false;

		if(!AxeComp.AxeImpulse.IsSet())
			return false;

		Params.AxeImpulse = AxeComp.AxeImpulse.Value;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DragonComp.DragonMesh.WorldLocation.Z < AxeComp.KillPlaneHeight)
			return true;

		if(ActiveDuration > AxeComp.Axe.MaxRagdollDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitTopDownSwingingAxePlayerHitActivationParams Params)
	{
		auto DragonMesh = DragonComp.DragonMesh;

		RagdollComp.ApplyRagdoll(DragonMesh, Player.CapsuleComponent);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragon, this);
		FRagdollImpulse NewImpulse = FRagdollImpulse(ERagdollImpulseType::WorldSpace, Params.AxeImpulse, AxeComp.Axe.ProngRoot.WorldLocation, n"Hips");
		RagdollComp.ApplyRagdollImpulse(DragonMesh, NewImpulse);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto DragonMesh = DragonComp.DragonMesh;

		Player.ActorLocation = DragonMesh.WorldLocation;
		RagdollComp.ClearRagdoll(DragonMesh, Player.CapsuleComponent);
		Player.KillPlayer();
		AxeComp.AxeImpulse.Reset();

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragon, this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(DragonComp == nullptr)
			DragonComp = UPlayerTeenDragonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};