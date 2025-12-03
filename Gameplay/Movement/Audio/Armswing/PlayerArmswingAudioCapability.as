class UPlayerArmswingAudioCapability : UHazePlayerCapability
{	
	default TickGroup = EHazeTickGroup::AfterPhysics;
	default DebugCategory = n"Audio";

	FVector CachedLeftHandLocation;
	FVector CachedRightHandLocation;
	FVector CachedPlayerLocation;

	UPlayerMovementAudioComponent PlayerMoveAudioComp;
	UPlayerArmswingMovementAudioSettings ArmswingSettings;

	FVector GetPlayerHipsLocation() const property
	{
		return Player.Mesh.GetSocketLocation(n"Hips");
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerMoveAudioComp = UPlayerMovementAudioComponent::Get(Player);
		ArmswingSettings = Cast<UPlayerArmswingMovementAudioSettings>(Player.GetSettings(UPlayerArmswingMovementAudioSettings));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MovementAudio::Player::CanPerformArmswing(PlayerMoveAudioComp))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MovementAudio::Player::CanPerformArmswing(PlayerMoveAudioComp))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CachedLeftHandLocation = GetHandLocation(EHandType::Left);
		CachedRightHandLocation = GetHandLocation(EHandType::Right);
		CachedPlayerLocation = PlayerHipsLocation;

		UMovementAudioEventHandler::Trigger_StartArmswing(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMovementAudioEventHandler::Trigger_StopArmswing(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		EvaluateHandVelo(EHandType::Left, DeltaTime);
		EvaluateHandVelo(EHandType::Right, DeltaTime);

		CachedPlayerLocation = PlayerHipsLocation;
	}

	void EvaluateHandVelo(const EHandType& Hand, float DeltaTime)
	{
		const float HandSpeed = GetNormalizedHandMovement(Hand, DeltaTime);	
		PlayerMoveAudioComp.SetHandVeloSpeed(Hand, HandSpeed);	

		const FVector NewLocation = GetHandLocation(Hand);

		if(MovementAudio::IsLeftHand(Hand))		
			CachedLeftHandLocation = NewLocation;
		else
			CachedRightHandLocation = NewLocation;		
	}

	float GetNormalizedHandMovement(const EHandType& Hand, float DeltaTime) const
	{
		const FVector Velo = GetHandDelta(Hand);
		if(Velo.IsNearlyZero())
			return 0.0;

		const float MovementSpeed = Velo.Size() / DeltaTime;
		const float NormalizedRange = MovementAudio::IsLeftHand(Hand) ? ArmswingSettings.LeftArmNormalizationRange : ArmswingSettings.RightArmNormalizationRange;

		return Audio::NormalizeRangeTo01(MovementSpeed, 0, NormalizedRange);
	}

	FVector GetHandLocation(const EHandType& Hand) const
	{
		FName WantedBoneName = MovementAudio::IsLeftHand(Hand) ? MovementAudio::Player::LeftArmswingSocketName : MovementAudio::Player::RightArmswingSocketName;
		return Player.Mesh.GetSocketLocation(WantedBoneName);
	}

	FVector GetHandDelta(const EHandType& Hand) const
	{
		const FVector CachedLocation = MovementAudio::IsLeftHand(Hand) ? CachedLeftHandLocation : CachedRightHandLocation;

		// Subtract movement made by the player, we only care about movement made by hand in relation to the body
		const FVector PlayerDelta = PlayerHipsLocation - CachedPlayerLocation;
		const FVector HandDelta = (GetHandLocation(Hand) - CachedLocation) - PlayerDelta;

		return HandDelta;
	}		

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		FName PlayerName = Player.IsMio() ? n"Mio" : n"Zoe";
		auto AudioLog = TEMPORAL_LOG(Player, "Audio/Armswing");

		LogToTemporal(EHandType::Left, AudioLog);
		LogToTemporal(EHandType::Right, AudioLog);
	}

	private void LogToTemporal(const EHandType Hand, FTemporalLog Log) const
	{
		FString Heading = Hand == EHandType::Left ? "Left;" : "Right;";
		Log.Value(f"{Heading}Velocity: ", GetHandDelta(Hand).Size());
	}
}