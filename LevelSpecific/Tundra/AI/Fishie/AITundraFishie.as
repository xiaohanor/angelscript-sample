UCLASS(Abstract)
class AAITundraFishie : ABasicAICharacter
{
	default CapsuleComponent.bOffsetBottomToAttachParentLocation = false;

	default CapabilityComp.DefaultCapabilities.Add(n"TundraFishieSwimmingMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"TundraFishieBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraFishieSwimAlongSplineMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraFishieSwimmingNoCollisionMovementCapability");
	
	UPROPERTY(DefaultComponent, ShowOnActor)
	UTundraFishieComponent FishieComp;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = "CharacterMesh0", AttachSocket = "Head")
	UTundraFishieMouthComp MouthComp;
	default MouthComp.RelativeLocation = FVector(20.0, 0.0, 40.0);
	default MouthComp.RelativeRotation = FRotator(70.0, 0.0, 0.0);
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnRespawn();		
		UHazeActorRespawnableComponent::Get(this).OnPostRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		// Tasty otter!
		TargetingComponent.SetTarget(Game::Mio);
		SetActorControlSide(Game::Mio);
	}
}

class UTundraFishieMouthComp : USceneComponent
{
}
