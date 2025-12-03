asset RemoteHackableStockMarketSheet of UHazeCapabilitySheet
{
	Capabilities.Add(URemoteHackableStockMarketCapability);
};

UCLASS(Abstract)
class ARemoteHackableStockMarket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	URemoteHackingResponseComponent HackingComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MonitorRoot;

	UPROPERTY(DefaultComponent, Attach = MonitorRoot)
	UStaticMeshComponent MonitorMeshComp;

	UPROPERTY(DefaultComponent, Attach = MonitorRoot)
	UWidgetComponent MonitorWidgetComp;

	UPROPERTY(DefaultComponent)
	USceneComponent ComputerRoot;

	UPROPERTY(DefaultComponent, Attach = ComputerRoot)
	UStaticMeshComponent ComputerMeshComp;

	UPROPERTY(DefaultComponent, Attach = MonitorRoot)
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(RemoteHackableStockMarketSheet);

	const float InitialStockValue = 620.25;
	const float MinPositiveRateOfChange = 1;
	const float MinNegativeRateOfChange = 0.01;
	const float MaxRateOfChange = 100.0;
	const float RandomInfluence = 0.2;
	const float ResetInfluence = 0.1;

	float InputValue = 0;
	float StockValue = InitialStockValue;

	private float RandomDir = 0;
	private float LastSetRandomDirTime = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cast<URemoteHackableStockMarketWidget>(MonitorWidgetComp.Widget).SetStockMarket(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Time::GetGameTimeSince(LastSetRandomDirTime) > 0.5)
			SetRandomDir();

		InputValue += RandomDir * RandomInfluence * DeltaSeconds;

		InputValue = Math::FInterpConstantTo(InputValue, 0, DeltaSeconds, ResetInfluence);

		InputValue = Math::Clamp(InputValue, -1, 1);

		float RateOfChange = 0;
		if(InputValue > 0)
		{
			RateOfChange = Math::Lerp(MinPositiveRateOfChange, MaxRateOfChange, Math::GetPercentageBetweenClamped(1, 650, StockValue));
		}
		else
		{
			RateOfChange = Math::Lerp(MinNegativeRateOfChange, MaxRateOfChange, Math::GetPercentageBetweenClamped(0.1, 650, StockValue));
		}

		StockValue += InputValue * RateOfChange * DeltaSeconds;

		StockValue = Math::Max(StockValue, 0);
	}

	void SetRandomDir()
	{
		RandomDir = Math::RandRange(-1, 1);
		LastSetRandomDirTime = Time::GameTimeSeconds;
	}
};