UCLASS(Abstract)
class APrisonDrones_Pigeon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent FauxTranslateComp;

	UPROPERTY(DefaultComponent, Attach = FauxTranslateComp)
	UFauxPhysicsWeightComponent FauxWeightComp;

	UPROPERTY(DefaultComponent, Attach = FauxWeightComp)
	UStaticMeshComponent MeshComp;

	default FauxWeightComp.MassScale = 0.5;
	default FauxWeightComp.bApplyInertia = false;
	
	UPROPERTY(DefaultComponent)
	UHackableSniperTurretResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		
		// Won't be called, already bound in BP.
		//ResponseComp.OnHackableSniperTurretHit.AddUFunction(this, n"SniperHit");
	}

	UFUNCTION()
	void SniperHit()
	{
		// Notify Zoe that a hit happened
		UPrisonDrones_PigeonEventHandler::Trigger_OnPigeonHit(Game::Zoe);
	}
};