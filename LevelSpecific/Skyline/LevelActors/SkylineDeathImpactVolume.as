asset SkylineDeathImpactSheet of UHazeCapabilitySheet
{
	AddCapability(n"SkylineDeathImpactCapability");
	Components.Add(UPlayerSkylineDeathImpactComponent);
}

class USkylineDeathImpactCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UPlayerMovementComponent MoveComp;
	UPlayerSkylineDeathImpactComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		UserComp = UPlayerSkylineDeathImpactComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.Volumes.IsDefaultValue())
			return false;
		
		if (!MoveComp.HasAnyValidBlockingContacts())
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
		ASkylineDeathImpactVolume Volume = UserComp.Volumes.Get();
		TSubclassOf<UDeathEffect> DeathEffect = nullptr;

		if (Volume != nullptr)
			DeathEffect = Volume.DeathEffect;
		
		Player.KillPlayer(FPlayerDeathDamageParams(), DeathEffect);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};

class ASkylineDeathImpactVolume : ACapabilitySheetVolume
{
    default Shape::SetVolumeBrushColor(this, FLinearColor(1.00, 0.50, 0.50));

	default PlayerSheets.Add(SkylineDeathImpactSheet);

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;
	default RequestComp.PlayerSheets.Add(SkylineDeathImpactSheet);

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDeathEffect> DeathEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"PlayerEntered");	
		OnPlayerLeave.AddUFunction(this, n"PlayerLeft");	
	}

    UFUNCTION()
    private void PlayerEntered(AHazePlayerCharacter Player)
    {
		UPlayerSkylineDeathImpactComponent::Get(Player).ApplyVolume(this, this);
    }

    UFUNCTION()
    private void PlayerLeft(AHazePlayerCharacter Player)
    {
		UPlayerSkylineDeathImpactComponent::Get(Player).ClearVolume(this);
    }

};

class UPlayerSkylineDeathImpactComponent : UActorComponent
{
	TInstigated<ASkylineDeathImpactVolume> Volumes;

	void ApplyVolume(ASkylineDeathImpactVolume Volume, FInstigator Instigator)
	{
		Volumes.Apply(Volume, Instigator);
	}

	void ClearVolume(FInstigator Instigator)
	{
		Volumes.Clear(Instigator);
	}
}