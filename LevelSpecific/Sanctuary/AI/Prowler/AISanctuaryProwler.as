UCLASS(Abstract)
class AAISanctuaryProwler : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryProwlerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryProwlerBehaviourSwapCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;


	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComp;

	UPROPERTY(DefaultComponent)
	ULightBirdTargetComponent LightBirdTargetComp;

	UPROPERTY(DefaultComponent)
	ULightBeamResponseComponent LightBeamResponseComp;

	UPROPERTY(DefaultComponent)
	ULightBeamTargetComponent LightBeamTargetComp;

	AHazePlayerCharacter SwapPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		LightBeamResponseComp.OnHitBegin.AddUFunction(this, n"OnHitBegin");
	}

	UFUNCTION()
	private void OnHitBegin(AHazePlayerCharacter Player)
	{
		SwapPlayer = Player;
	}
}
