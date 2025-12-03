
class UPlayerSkydiveComponent : UActorComponent
{
	access InternalWithCapability = private, UPlayerSkydiveCapability;
	
	UPROPERTY(Category = "SkydiveSettings")
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(Category = "SkydiveSettings")
	TSubclassOf<UCameraShakeBase> CamShake_GroundedLanding;

	UPROPERTY(Category = "SkydiveSettings")
	TSubclassOf<UCameraShakeBase> CamShake_WaterLanding;

	UPROPERTY(Category = "SkydiveSettings")
	UForceFeedbackEffect ForceFeedback_GroundedLanding;

	UPROPERTY(Category = "SkydiveSettings")
	UForceFeedbackEffect ForceFeedback_WaterLanding;

	UPROPERTY(Category = "SkydiveSettings")
	UNiagaraSystem SkydiveOutlineEffect;

	UPlayerMovementComponent MoveComp;
	UPlayerSkydiveSettings Settings;
	FPlayerSkydiveAnimationData AnimData;

	private bool bIsSkyDiveActive = false;
	private	TInstigated<FPlayerSkydiveInstigatedData> InstigatedSkydive;
	private TArray<FInstigator> SkydiveInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerSkydiveSettings::GetSettings(Cast<AHazeActor>(Owner));
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		if(!InstigatedSkydive.IsDefaultValue())
		{
			const FPlayerSkydiveInstigatedData& CurrentSkydive = InstigatedSkydive.Get();
			GetTemporalLog().Section("InstigatedSkydive")
				.Value("ShouldActivate", CurrentSkydive.ShouldActivate)
				.Value("Mode", CurrentSkydive.Mode)
				.Value("Style", CurrentSkydive.Style)
				.Value("Instigator", CurrentSkydive.Instigator)
			;
		}

		for(int i = 0; i < SkydiveInstigators.Num(); i++)
		{
			GetTemporalLog().Section("Skydive Instigators").Value(f"Instigator {i}", SkydiveInstigators[i]);
		}

		if(IsSkydiveActive())
		{
			GetTemporalLog().Section("AnimData")
				.Value("SkydiveInput", AnimData.SkydiveInput)
				.Value("bLandingDetected", AnimData.bLandingDetected)
				.Value("bWaterLandingDetected", AnimData.bWaterLandingDetected)
				.Value("bLandingIsBlocked", AnimData.bLandingIsBlocked)
				.Value("Style", AnimData.Style)
				.Value("RemainingHeightForLanding", AnimData.RemainingHeightForLanding)
			;
		}
#endif
	}

	access:InternalWithCapability
	bool ShouldActivateSkydive() const
	{
		return InstigatedSkydive.Get().ShouldActivate;
	}

	UFUNCTION()
	bool IsSkydiveActive() const
	{
		return bIsSkyDiveActive;
	}

	bool GetShouldSkipEnter() const property
	{
		return InstigatedSkydive.Get().bShouldSkipEnter;
	}

	EPlayerSkydiveMode GetCurrentSkydiveMode() const property
	{
		return InstigatedSkydive.Get().Mode;
	}

	EPlayerSkydiveStyle GetCurrentSkydiveStyle() const property
	{
		return InstigatedSkydive.Get().Style;
	}

	UFUNCTION()
	void ApplySkydiveActivation(FInstigator Instigator, EPlayerSkydiveMode Mode, EInstigatePriority SkydivePriority, UPlayerSkydiveSettings SettingsToApply, EHazeSettingsPriority SettingsPriority, EPlayerSkydiveStyle Style = EPlayerSkydiveStyle::Falling, bool bSkipEnter = false)
	{
		FInstigator NamedInstigator = Instigator.WithName(n"Skydive");

		FPlayerSkydiveInstigatedData Data;
		Data.ShouldActivate = true;
		Data.bShouldSkipEnter = bSkipEnter;
		Data.Mode = Mode;
		Data.Style = Style;
		Data.Instigator = NamedInstigator;
		InstigatedSkydive.Apply(Data, NamedInstigator, SkydivePriority);

		if(SettingsToApply != nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);

			Player.ApplySettings(SettingsToApply, NamedInstigator, SettingsPriority);
			UMovementGravitySettings::SetGravityAmount(Player, SettingsToApply.GravityAmount, NamedInstigator, SettingsPriority);
			UMovementGravitySettings::SetTerminalVelocity(Player, SettingsToApply.TerminalVelocity, NamedInstigator, SettingsPriority);
		}

		SkydiveInstigators.AddUnique(NamedInstigator);

#if !RELEASE
		GetTemporalLog().Event(f"Applied by {Instigator}");
		UpdatePersistentStatus();
#endif
	}

	UFUNCTION()
	void ClearSkyDiveActivation(FInstigator Instigator)
	{
		FInstigator NamedInstigator = Instigator.WithName(n"Skydive");

		InstigatedSkydive.Clear(NamedInstigator);

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		Player.ClearSettingsOfClass(UPlayerSkydiveSettings, NamedInstigator);
		Player.ClearSettingsOfClass(UMovementGravitySettings, NamedInstigator);

		SkydiveInstigators.RemoveSwap(NamedInstigator);

#if !RELEASE
		GetTemporalLog().Event(f"Cleared by {Instigator}");
		UpdatePersistentStatus();
#endif
	}

	//Will be called when skydive deactivates due to becoming grounded
	UFUNCTION()
	void ClearAllSkydiveActivations()
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);

		for (int i = 0; i < SkydiveInstigators.Num(); i++)
		{
			FInstigator CurrentInstigator = InstigatedSkydive.GetCurrentInstigator();
			Player.ClearSettingsOfClass(UPlayerSkydiveSettings, CurrentInstigator);
			Player.ClearSettingsOfClass(UMovementGravitySettings, CurrentInstigator);
			InstigatedSkydive.Clear(CurrentInstigator);
		}

		SkydiveInstigators.Reset();

#if !RELEASE
		GetTemporalLog().Event(f"Cleared All");
		UpdatePersistentStatus();
#endif
	}

	access:InternalWithCapability
	void ActivateSkydive()
	{
		bIsSkyDiveActive = true;

#if !RELEASE
		UpdatePersistentStatus();
#endif
	}

	access:InternalWithCapability
	void DeactivateSkydive()
	{
		bIsSkyDiveActive = false;
		AnimData.ResetData();

#if !RELEASE
		UpdatePersistentStatus();
#endif
	}

	FVector CalculateSkydiveAirControlVelocity(
		FVector MovementInput,
		FVector PreviousVelocity,
		float DeltaTime,
		float AirControlMultiplier = 1.0,
		float AirMovementSpeedMultiplier = 1.0
	)
	{
		float TargetMovementSpeed = Settings.HorizontalMoveSpeed;
		TargetMovementSpeed *= MoveComp.MovementSpeedMultiplier;
		TargetMovementSpeed *= AirMovementSpeedMultiplier;

		float TargetMaximumSpeedBeforeDrag = Settings.MaximumHorizontalMoveSpeedBeforeDrag;
		TargetMaximumSpeedBeforeDrag *= MoveComp.MovementSpeedMultiplier;
		TargetMaximumSpeedBeforeDrag *= AirMovementSpeedMultiplier;

		float InterpSpeed = Settings.HorizontalVelocityInterpSpeed * AirControlMultiplier;
		float DragSpeed = Settings.DragOfExtraHorizontalVelocity;

		// Zero input will deccelerate down to 0
	    if (MovementInput.IsNearlyZero())
		{
			float VelocitySize = PreviousVelocity.Size();
			VelocitySize = Math::FInterpConstantTo(VelocitySize, 0, DeltaTime, Settings.HorizontalDeccelerationSpeed);
		}

		// Zero velocity returns the the input
		if (PreviousVelocity.IsNearlyZero())
		{
			return Math::VInterpConstantTo(
				PreviousVelocity,
				MovementInput.GetSafeNormal() * TargetMovementSpeed,
				DeltaTime, InterpSpeed);
		}

		const FVector WorldUp = MoveComp.GetWorldUp();
		const float Alignment = MovementInput.VectorPlaneProject(WorldUp).GetSafeNormal().DotProductNormalized(PreviousVelocity.VectorPlaneProject(WorldUp).GetSafeNormal());
		const FVector WorstInputVelocity = MovementInput * TargetMovementSpeed;

		float BestInputSpeed = PreviousVelocity.Size();
		if (BestInputSpeed > TargetMaximumSpeedBeforeDrag)
			BestInputSpeed = Math::Max(BestInputSpeed - (DragSpeed * DeltaTime), TargetMaximumSpeedBeforeDrag);
		else
			BestInputSpeed = Math::Max(BestInputSpeed, TargetMovementSpeed);

		const FVector BestInputVelocity = MovementInput * BestInputSpeed;

		FVector TargetVelocity = Math::Lerp(WorstInputVelocity, BestInputVelocity, Alignment);
		FVector NewForward = Math::VInterpConstantTo(PreviousVelocity, TargetVelocity, DeltaTime, InterpSpeed); 

		return NewForward;
	}

#if !RELEASE
	FTemporalLog GetTemporalLog() const
	{
		return TEMPORAL_LOG(this, Owner, "Skydive");
	}

	private void UpdatePersistentStatus()
	{
		if(IsSkydiveActive())
			GetTemporalLog().PersistentStatus("Is Active", FLinearColor::Green);
		else if(ShouldActivateSkydive())
			GetTemporalLog().PersistentStatus("Should Activate", FLinearColor::Yellow);
		else
			GetTemporalLog().PersistentStatus("Inactive", FLinearColor::Red);
	}
#endif
}

struct FPlayerSkydiveAnimationData
{
	UPROPERTY()
	FVector2D SkydiveInput;
	
	UPROPERTY()
	bool bLandingDetected;

	UPROPERTY()
	bool bWaterLandingDetected;

	UPROPERTY()
	bool bLandingIsBlocked;

	UPROPERTY()
	EPlayerSkydiveStyle Style;

	/* WARNING, This can snap wildly if players navigate steer on top of closer terrain
	 * will be -1 if no landing is detected
	 */
	UPROPERTY()
	float RemainingHeightForLanding;

	void ResetData()
	{
		SkydiveInput = FVector2D::ZeroVector;
		bLandingDetected = false;
		bWaterLandingDetected = false;
		RemainingHeightForLanding = -1;
		bLandingIsBlocked = false;
	}

}

struct FPlayerSkydiveInstigatedData
{
	bool ShouldActivate = false;
	bool bShouldSkipEnter = false;
	EPlayerSkydiveMode Mode = EPlayerSkydiveMode::Default;
	EPlayerSkydiveStyle Style = EPlayerSkydiveStyle::Falling;
	FInstigator Instigator;
}

enum EPlayerSkydiveMode
{
	Default,
	Strafe
}

enum EPlayerSkydiveStyle
{
	Falling,
	Diving
}