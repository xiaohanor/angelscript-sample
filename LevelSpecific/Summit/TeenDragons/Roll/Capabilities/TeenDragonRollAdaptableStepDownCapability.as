class UTeenDragonRollAdaptableStepDownCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	UPlayerMovementComponent MoveComp;
	UTeenDragonRollComponent RollComp;

	UMovementSteppingSettings SteppingSettings;

	FVector AverageGroundNormal;

	const float AverageNormalInterpDegreesPerSecond = 40.0;
	const float StepDownFractionMin = 0.1;
	const float NormalDeltaAngleForStepDownMin = 90.0;
	const float AheadTraceDistance = 400.0;
	const float UpwardsTraceDistance = 300.0;

	float StartStepDownFraction;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);
		
		SteppingSettings = UMovementSteppingSettings::GetSettings(Player);

		AverageGroundNormal = FVector::UpVector;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!RollComp.IsRolling())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!RollComp.IsRolling())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartStepDownFraction = SteppingSettings.StepDownSize.Value;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeTraceSettings GroundTrace;
		GroundTrace.TraceWithPlayerProfile(Player);
		GroundTrace.UseLine();
		GroundTrace.IgnorePlayers();

		FVector Start = Player.ActorLocation 
			+ (AverageGroundNormal * UpwardsTraceDistance)
			+ (Player.ActorVelocity.GetSafeNormal() * AheadTraceDistance);
		FVector End = Start - (AverageGroundNormal * (UpwardsTraceDistance * 2));
		auto Hits = GroundTrace.QueryTraceMulti(Start, End);
		
		auto TempLogPage = TEMPORAL_LOG(Player, "Teen Dragon Roll").Page("Adaptable Step Down");

		TempLogPage
			.Arrow("Trace", Start, End, 10, 20, FLinearColor::Blue)
		;
		
		FHitResult ChosenHit;
		for(auto Hit : Hits)
		{
			if(Hit.Actor.IsA(ASummitNightQueenGem))
				continue;

			if(Hit.bBlockingHit)
			{
				ChosenHit = Hit;
				break;
			}
		}

		if(ChosenHit.bBlockingHit)
		{
			TempLogPage
				.Sphere("Adaptable Step Down Hit", ChosenHit.ImpactPoint, 10, FLinearColor::Blue, 2)
			;
			AverageGroundNormal = Math::VInterpNormalRotationTo(AverageGroundNormal, ChosenHit.Normal, DeltaTime, AverageNormalInterpDegreesPerSecond);
		}

		FVector CompareNormal;
		CompareNormal = ChosenHit.ImpactNormal;
		float DegreesToLastNormal = AverageGroundNormal.GetAngleDegreesTo(CompareNormal);
		float DeltaDegreesToMaxAlpha = Math::GetPercentageBetweenClamped(0, NormalDeltaAngleForStepDownMin, DegreesToLastNormal);
		float LerpedStepDownValue = Math::Lerp(StartStepDownFraction, StepDownFractionMin, DeltaDegreesToMaxAlpha);
		FMovementSettingsValue StepDownValue = FMovementSettingsValue::MakePercentage(LerpedStepDownValue);
		SteppingSettings.bOverride_StepDownSize = true;
		SteppingSettings.StepDownSize = StepDownValue;
		TempLogPage
			.DirectionalArrow("Average Ground Normal", Player.ActorLocation, AverageGroundNormal * 1000, 10, 20, FLinearColor::White)
			.Value("Step Down Fraction", StepDownValue.Value)
		;
	}
};