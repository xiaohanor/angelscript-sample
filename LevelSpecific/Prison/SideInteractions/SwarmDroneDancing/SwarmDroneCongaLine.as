asset Sheet_Prison_SwarmDrone_CongaLine of UHazeCapabilitySheet
{
	Components.Add(UPlayerSwarmDroneCongaLineComponent);
	Capabilities.Add(USwarmDroneCongaLineCapability);
	Blocks.Add(CapabilityTags::Movement);
}

class ASwarmDroneCongaLine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent PlatformBase;

	UPROPERTY(DefaultComponent)
	USceneComponent SpotlightRoot;

	UPROPERTY(DefaultComponent, Attach = SpotlightRoot)
	USpotLightComponent Spotlight1;

	UPROPERTY(DefaultComponent, Attach = SpotlightRoot)
	USpotLightComponent Spotlight2;

	UPROPERTY(DefaultComponent)
	USwarmDroneCongaLineTriggerComponent TriggerComponent;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent SplineComponent;


	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent PlayerCapabilityRequestComponent;
	default PlayerCapabilityRequestComponent.InitialStoppedSheets_Mio.Add(Sheet_Prison_SwarmDrone_CongaLine);

	float Light1Intensity;
	float Light2Intensity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		TriggerComponent.OnPlayerEnter.AddUFunction(this, n"OnCongaLineStart");
		TriggerComponent.OnPlayerLeave.AddUFunction(this, n"OnCongaLineStop");

		Light1Intensity = Spotlight1.Intensity;
		Light2Intensity = Spotlight2.Intensity;

		Spotlight1.SetIntensity(0);
		Spotlight2.SetIntensity(0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float Speed = 3;

		float SpotlightIntensity = Math::Square(Math::Abs(Math::Sin(Time::GameTimeSeconds * Speed))) * Light1Intensity;
		Spotlight1.SetIntensity(SpotlightIntensity);

		SpotlightIntensity = Math::Square(Math::Abs(Math::Cos(Time::GameTimeSeconds * Speed))) * Light2Intensity;
		Spotlight2.SetIntensity(SpotlightIntensity);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnCongaLineStart(AHazePlayerCharacter Player)
	{
		PlayerCapabilityRequestComponent.StartInitialSheetsAndCapabilities(Drone::GetSwarmDronePlayer(), this);
		UPlayerSwarmDroneCongaLineComponent PlayerCongaLineComponent = UPlayerSwarmDroneCongaLineComponent::Get(Player);
		PlayerCongaLineComponent.CongaLine = this;

		SetActorTickEnabled(true);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnCongaLineStop(AHazePlayerCharacter Player)
	{
		PlayerCapabilityRequestComponent.StopInitialSheetsAndCapabilities(Drone::GetSwarmDronePlayer(), this);

		SetActorTickEnabled(false);

		Spotlight1.SetIntensity(0);
		Spotlight2.SetIntensity(0);
	}
}