enum EDragonForm
{
	Baby,
	Teen,
	Adult
}

class UDragonMovementAudioComponent : UHazeMovementAudioComponent
{
	UPROPERTY(EditDefaultsOnly)
	UAudioDragonFootTraceSettings TraceSettings;

	UPROPERTY(EditDefaultsOnly)
	UAudioDragonFootTraceSettings WalkTraceSettings;

	UPROPERTY(EditDefaultsOnly)
	UDragonMovementAudioSettings MovementSettings;

	UPROPERTY(EditDefaultsOnly)
	EDragonForm Form;

	AHazePlayerCharacter PlayerDragonRider = nullptr;
	UHazeMovementComponent MoveComp;

	private float BodyMovementSocketRelativeSpeed = 0;
	private float BodyMovementVeloSpeed = 0;

	private float LeftWingSocketRelativeSpeed = 0;
	private float RightWingSocketRelativeSpeed = 0;
	private float LeftWingSocketRelativeDirection = 0;
	private float RightWingSocketRelativeDirection = 0;


	UPROPERTY(BlueprintReadOnly)
	bool bIsRolling = false;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazeActor DragonOwner = Cast<AHazeActor>(GetOwner());

		if(Form == EDragonForm::Teen)
		{
			ATeenDragon TeenDragon = Cast<ATeenDragon>(GetOwner());
			PlayerDragonRider = TeenDragon.IsAcidDragon() ? Game::GetMio() : Game::GetZoe();
		}
		else if(Form == EDragonForm::Adult)
		{
			AAdultDragon AdultDragon = Cast<AAdultDragon>(GetOwner());
			PlayerDragonRider = AdultDragon.IsAcidDragon() ? Game::GetMio() : Game::GetZoe();
		}

		
		if(TraceSettings != nullptr && PlayerDragonRider != nullptr)
			PlayerDragonRider.ApplySettings(TraceSettings, this);

		if(MovementSettings != nullptr && PlayerDragonRider != nullptr)
			PlayerDragonRider.ApplySettings(MovementSettings, this);		

		MoveComp = UHazeMovementComponent::Get(PlayerDragonRider);
		OnMovementTagChanged.AddUFunction(this, n"OnDragonMovementChanged");
	}

	UFUNCTION(BlueprintPure, DisplayName = "Dragon Normalized Movement Speed")
	float GetBodyMovementVelocitySpeed()
	{
		return BodyMovementVeloSpeed;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Dragon Body Movement Normalized Speed")
	float GetBodyMovementSocketRelativeVelocitySpeed()
	{
		return BodyMovementVeloSpeed;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Dragon Wings Normalized Movement")
	void GetWingSocketsRelativeVelocitySpeed(float&out Left, float&out Right, float&out LeftDirection, float&out RightDirection)
	{
		Left = LeftWingSocketRelativeSpeed;
		Right = RightWingSocketRelativeSpeed;
		LeftDirection = LeftWingSocketRelativeDirection;
		RightDirection = RightWingSocketRelativeDirection;
	}

	void SetBodyMovementSocketRelativeSpeed(const float InSpeed)
	{
		BodyMovementSocketRelativeSpeed = InSpeed;
	}

	void SetBodyMovementVelocitySpeed(const float InSpeed)
	{
		BodyMovementVeloSpeed = InSpeed;
	}

	void SetWingSocketsRelativeSpeed(const float InLeft, const float InRight, const float InLeftDirection, const float InRightDirection)
	{
		LeftWingSocketRelativeSpeed = InLeft;
		RightWingSocketRelativeSpeed = InRight;

		LeftWingSocketRelativeDirection = InLeftDirection;
		RightWingSocketRelativeDirection = InRightDirection;
	}

	UFUNCTION(BlueprintCallable)
	void SetIsRolling(const bool bInIsRolling)
	{
		bIsRolling = bInIsRolling;
	}

	UFUNCTION(BlueprintPure)
	int32 IsRollingInvertedMultiplier()
	{
		return bIsRolling ? 0 : 1;
	}

	UFUNCTION(BlueprintPure)
	float IsRollingInAirMultiplier()
	{
		if(!bIsRolling)
			return 0.0;

		return MoveComp.IsOnAnyGround() ? 0.0 : 1.0;
	}

	UFUNCTION()
	void OnDragonMovementChanged(FName Group, FName NewTag, bool bIsEnter, bool bIsOverride)
	{
		if(Group == n"Dragon_Foot" && NewTag == n"Walk")
		{
			if(bIsEnter)
				PlayerDragonRider.ApplySettings(WalkTraceSettings, this, EHazeSettingsPriority::Override);
			else
				PlayerDragonRider.ClearSettingsWithAsset(WalkTraceSettings, this);
		}
	}
}