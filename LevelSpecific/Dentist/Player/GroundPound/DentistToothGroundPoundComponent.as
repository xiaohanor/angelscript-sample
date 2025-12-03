enum EDentistToothGroundPoundState
{
	None,
	Anticipation,
	Drop,
	Recover,
};

struct FDentistGroundPoundOnGroundHit
{
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactLocation;

	UPROPERTY(BlueprintReadOnly)
	FVector Normal;

	UPROPERTY(BlueprintReadOnly)
	UDentistToothMovementResponseComponent MovementResponseComp;
}


class UDentistToothGroundPoundComponent : UActorComponent
{
	private AHazePlayerCharacter Player;
	private UPlayerMovementComponent MoveComp;
	UDentistToothGroundPoundSettings Settings;

	EDentistToothGroundPoundState CurrentState = EDentistToothGroundPoundState::None;
	EDentistToothGroundPoundState DesiredState = EDentistToothGroundPoundState::None;

	private int AirGroundPoundCount = 0;
	UDentistGroundPoundAutoAimComponent AutoAimTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Settings = UDentistToothGroundPoundSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(MoveComp.IsOnAnyGround())
			ResetAirGroundPoundUsage();

		#if EDITOR
		TEMPORAL_LOG(this)
			.Value("CurrentState", CurrentState)
			.Value("DesiredState", DesiredState)
		;
		#endif
	}

	void StartGroundPound(bool bIsAirGroundPound, UDentistGroundPoundAutoAimComponent InAutoAimTarget)
	{
		check(!IsGroundPounding());

		CurrentState = EDentistToothGroundPoundState::None;
		DesiredState = EDentistToothGroundPoundState::Anticipation;

		if(bIsAirGroundPound)
			AirGroundPoundCount++;

		AutoAimTarget = InAutoAimTarget;
		if(AutoAimTarget != nullptr)
			MoveComp.FollowComponentMovement(InAutoAimTarget, this, EMovementFollowComponentType::ResolveCollision, EInstigatePriority::High);
	
		UDentistToothEventHandler::Trigger_OnStartGroundPound(Player);
	}

	void StopGroundPound(bool bFinished)
	{
		if(CurrentState == EDentistToothGroundPoundState::None)
			return;

		DesiredState = EDentistToothGroundPoundState::None;
		
		if(IsGroundPounding())
			CurrentState = EDentistToothGroundPoundState::None;

		if(AutoAimTarget != nullptr)
		{
			MoveComp.UnFollowComponentMovement(this);
			AutoAimTarget = nullptr;
		}

		UDentistToothEventHandler::Trigger_OnStopGroundPound(Player);
	}

	bool IsGroundPounding() const
	{
		switch(CurrentState)
		{
			case EDentistToothGroundPoundState::None:
				return false;

			case EDentistToothGroundPoundState::Anticipation:
				return true;

			case EDentistToothGroundPoundState::Drop:
				return true;

			case EDentistToothGroundPoundState::Recover:
				return false;
		}
	}

	bool CanAirGroundPound() const
	{
		return AirGroundPoundCount < Settings.MaxAirGroundPoundCount;
	}

	void ResetAirGroundPoundUsage()
	{
		AirGroundPoundCount = 0;
	}
};