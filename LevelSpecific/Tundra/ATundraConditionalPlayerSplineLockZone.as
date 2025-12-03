class ATundraConditionalPlayerSplineLockZone : APlayerSplineLockZone
{
	default SetActorTickEnabled(false);

	UPROPERTY(EditInstanceOnly, Category = "Conditions")
	FName CapabilityTag;

	private TPerPlayer<FTundraConditionalPlayerSplineLockData> PerPlayerConditionalVolumeData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto PlayerData : PerPlayerConditionalVolumeData)
		{
			if(PlayerData.bIsPlayerInside)
			{
				if(!PlayerData.bIsActiveForPlayer)
				{
					if(PlayerData.Player.IsAnyCapabilityActive(CapabilityTag))
						OnConditionValid(PlayerData.Player);
				}
				else
				{
					if(!PlayerData.Player.IsAnyCapabilityActive(CapabilityTag))
						OnConditionFailed(PlayerData.Player);
				}
			}
		}
	}

	void OnPlayerTriggerEnter(AHazePlayerCharacter Player) override
	{
		if(!IsActorTickEnabled())
			SetActorTickEnabled(true);

		PerPlayerConditionalVolumeData[Player].bIsPlayerInside = true;
		PerPlayerConditionalVolumeData[Player].Player = Player;

		if(!Player.IsAnyCapabilityActive(CapabilityTag))
			return;
		
		UTundraPlayerSplineLockReleaseByInputComponent InputReleaseComp = UTundraPlayerSplineLockReleaseByInputComponent::Get(Player);
		InputReleaseComp.ActiveSplineLockZone = this;

		PerPlayerConditionalVolumeData[Player].bIsActiveForPlayer = true;
		Super::OnPlayerTriggerEnter(Player);
	}

	void OnConditionValid(AHazePlayerCharacter Player)
	{
		PerPlayerConditionalVolumeData[Player].bIsActiveForPlayer = true;

		auto PlayerSplineLockComponent = UPlayerSplineLockComponent::Get(Player);
		if(PlayerSplineLockComponent == nullptr)
			return;
		
		UTundraPlayerSplineLockReleaseByInputComponent InputReleaseComp = UTundraPlayerSplineLockReleaseByInputComponent::Get(Player);
		InputReleaseComp.ActiveSplineLockZone = this;

		PlayerSplineLockComponent.ActivateSplineZone(this);
		Player.ApplyGameplayPerspectiveMode(PerspectiveMode, this);
	}

	void OnPlayerTriggerLeave(AHazePlayerCharacter Player) override
	{
		UTundraPlayerSplineLockReleaseByInputComponent InputReleaseComp = UTundraPlayerSplineLockReleaseByInputComponent::Get(Player);
		InputReleaseComp.ActiveSplineLockZone = nullptr;

		PerPlayerConditionalVolumeData[Player].Reset();
		Super::OnPlayerTriggerLeave(Player);

		if(!PerPlayerConditionalVolumeData[Game::GetMio()].bIsPlayerInside && !PerPlayerConditionalVolumeData[Game::GetZoe()].bIsPlayerInside)
			SetActorTickEnabled(false);
	}

	void OnConditionFailed(AHazePlayerCharacter Player)
	{
		PerPlayerConditionalVolumeData[Player].bIsActiveForPlayer = false;

		auto PlayerSplineLockComponent = UPlayerSplineLockComponent::Get(Player);
		if(PlayerSplineLockComponent == nullptr)
			return;

		UTundraPlayerSplineLockReleaseByInputComponent InputReleaseComp = UTundraPlayerSplineLockReleaseByInputComponent::Get(Player);
		InputReleaseComp.ActiveSplineLockZone = nullptr;

		PlayerSplineLockComponent.DeactivateSplineZone(this);
		Player.ClearGameplayPerspectiveMode(this);
	}
};

struct FTundraConditionalPlayerSplineLockData
{
	AHazePlayerCharacter Player;
	bool bIsPlayerInside = false;
	bool bIsActiveForPlayer = false;

	void Reset()
	{
		Player = nullptr;
		bIsPlayerInside = false;
		bIsPlayerInside = false;
	}
}