class UAir_Movement_SoundDef : USoundDefBase
{
	protected AHazePlayerCharacter Player;
	protected UHazeMovementComponent MoveComp;
	protected UHazeMovementAudioComponent AudioMoveComp;

	UPROPERTY(BlueprintReadOnly, Category = "Audio Events", Meta = (DisplayName = "Event - Cloth Fall"))
	UHazeAudioEvent FallLoopEvent = nullptr;

	UPROPERTY(BlueprintReadWrite, NotVisible)
	FVector FallingStartLocation;

	UPROPERTY(BlueprintReadWrite, NotVisible)
	float FallingDistance = 0.0;

	const float MAX_VERTICAL_SPEED = 2500;
	const float MAX_HORIZONTAL_SPEED = 600;

	bool GetbIsBlocked() const property
	{
		return AudioMoveComp.IsMovementBlocked(EMovementAudioFlags::Falling);
	}

	bool IsRequested() const
	{
		return AudioMoveComp.CanPerformMovement(EMovementAudioFlags::Falling);
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Player = Cast<AHazePlayerCharacter>(HazeOwner);
		MoveComp = UHazeMovementComponent::Get(HazeOwner);
		AudioMoveComp = UHazeMovementAudioComponent::Get(HazeOwner);

		auto VariantComp = UPlayerVariantComponent::Get(HazeOwner);
		FallLoopEvent = VariantComp.GetPlayerVariantArmswingEvents(Player).FallLoopEvent;
	}

	UFUNCTION(BlueprintPure)
	bool IsGrounded()
	{
											// Just to be safe
		return MoveComp.IsOnAnyGround() && !PlayerOwner.IsPlayerDead();
	}

	UFUNCTION(BlueprintPure)
	float GetDistanceToGroundNormalized(const float NormalizeRange)
	{
		const FVector ToGround = Player.MovementWorldUp * -1;

		const FVector TraceStart = Player.Mesh.GetSocketLocation(n"Hips");
		const FVector TraceEnd = TraceStart + (ToGround * NormalizeRange);

		//Debug::DrawDebugLine(TraceStart, TraceEnd);

		FHazeTraceSettings TraceSettings;
		TraceSettings.TraceWithPlayerProfile(Player);
		TraceSettings.UseLine();

		auto HitResult = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);

		if(!HitResult.bBlockingHit)
			return 0.0;

		return 1 - HitResult.Distance / NormalizeRange;
	}

	UFUNCTION(BlueprintPure)
	void GetAirMovement(float&out Vertical, float&out Horizontal)
	{
		const int VerticalSign = int(Math::Sign(MoveComp.GetVerticalSpeed()));
		Vertical = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_VERTICAL_SPEED), FVector2D(0.0, 1.0), Math::Abs(MoveComp.GetVerticalSpeed()));	
		Vertical *= VerticalSign;

		Horizontal = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_HORIZONTAL_SPEED), FVector2D(0.0, 1.0), MoveComp.HorizontalVelocity.Size());
	}
}