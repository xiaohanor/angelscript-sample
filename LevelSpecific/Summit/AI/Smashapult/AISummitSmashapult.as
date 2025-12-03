UCLASS(Abstract)
class AAISummitSmashapult : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SummitSmashapultMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIClimbAlongSplineMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"SummitSmashapultBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AISummitMeltCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitSmashapultAcidResponseCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitSmashapultLaunchCapability");

	default CapsuleComponent.CapsuleRadius = 1000;
	default CapsuleComponent.CapsuleHalfHeight = CapsuleComponent.CapsuleRadius;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = "CharacterMesh0", AttachSocket = "Attach")
	UBasicAINetworkedProjectileLauncherComponent ProjectileLauncher;

	USummitSmashapultSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		Super::BeginPlay();

		OnRespawn();
		RespawnComp.OnPostRespawn.AddUFunction(this, n"OnRespawn");

		Settings = USummitSmashapultSettings::GetSettings(this);
		UBasicAISettings::SetSplineEntranceMoveSpeed(this, Settings.SplineEntranceMoveSpeed, this, EHazeSettingsPriority::Defaults);
	}

	UFUNCTION()
	private void OnRespawn()
	{
		// Always target ball player
		TargetingComponent.SetTarget(Game::Zoe);
	}
}