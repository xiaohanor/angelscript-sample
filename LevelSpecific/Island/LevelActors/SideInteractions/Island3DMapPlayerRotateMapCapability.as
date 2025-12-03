asset Island3DMapPlayerCapabilitySheet of UHazeCapabilitySheet
{
	Capabilities.Add(UIsland3DMapPlayerRotateMapCapability);
}

class UIsland3DMapPlayerRotateMapCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UIsland3DMapPlayerComponent MapComponent;
	UPlayerMovementComponent MovementComponent;
	AIsland3DMap Island3DMap;
	UHazeActionQueueComponent NetworkedDelayedDeactivateQueue;

	FHazeAcceleratedFloat AcceleratedYaw;
	float LastGametimestamp = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MapComponent = UIsland3DMapPlayerComponent::GetOrCreate(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MapComponent.IslandMap == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MapComponent.IslandMap == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (Island3DMap == nullptr)
		{
			Island3DMap = MapComponent.IslandMap;
			if (Network::IsGameNetworked())
				NetworkedDelayedDeactivateQueue = UHazeActionQueueComponent::Create(Island3DMap);
		}

		if (NetworkedDelayedDeactivateQueue != nullptr && !NetworkedDelayedDeactivateQueue.IsEmpty())
			NetworkedDelayedDeactivateQueue.Empty();

		Island3DMap.SyncedSmallMapYaw.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		Player.ShowTutorialPrompt(Island3DMap.TutorialPromptRotateMap, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Island3DMap.SyncedSmallMapYaw.OverrideSyncRate(EHazeCrumbSyncRate::Low);
		Player.RemoveTutorialPromptByInstigator(this);
		if (NetworkedDelayedDeactivateQueue != nullptr)
		{
			NetworkedDelayedDeactivateQueue.Duration(Network::PingRoundtripSeconds * 2.0, this, n"NetworkSettleSyncedRotation");
		}
	}

	UFUNCTION()
	private void NetworkSettleSyncedRotation(float Alpha)
	{
		SyncSetRotation();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.HasControl())
		{
			FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			float UsedYawInput = 0.0;
			if (!Math::IsNearlyEqual(MoveInput.Y, 0.0, KINDA_SMALL_NUMBER))
				UsedYawInput = MoveInput.Y;
			float CurrentYaw = Island3DMap.SyncedSmallMapYaw.Value;
			Island3DMap.SyncedSmallMapYaw.SetValue(CurrentYaw + (UsedYawInput * DeltaTime * Island3DMap.RotateSpeedDegrees * -1.0));
		}
		SyncSetRotation();
	}

	void SyncSetRotation()
	{
		FRotator NewRelativeRotation = Island3DMap.OGSmallMapRootRotation;
		if (LastGametimestamp <= KINDA_SMALL_NUMBER)
			LastGametimestamp = Time::GameTimeSeconds;
		float FakeDeltaTime = Time::GameTimeSeconds - LastGametimestamp;
		LastGametimestamp = Time::GameTimeSeconds;
		AcceleratedYaw.AccelerateTo(Island3DMap.SyncedSmallMapYaw.Value, 0.5, FakeDeltaTime);
		NewRelativeRotation.Yaw += Math::Wrap(AcceleratedYaw.Value, 0.0, 360.0);
		Island3DMap.SmallMapRoot.SetRelativeRotation(NewRelativeRotation);
	}
};