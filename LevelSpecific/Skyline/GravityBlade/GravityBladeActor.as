namespace GravityBlade
{
	UFUNCTION(Category = "Gravity Blade", DisplayName = "Get Gravity Blade")
	AGravityBladeActor Get() 
	{
		TArray<AActor> AttachedActors;
		Game::Mio.GetAttachedActors(AttachedActors, false, false);
		for(const auto IterActor : AttachedActors)
		{
			AGravityBladeActor Blade = Cast<AGravityBladeActor>(IterActor);
			if(Blade != nullptr)
			{
				return Blade;
			}
		}
		return nullptr;
	}

	// Event handler events aren't 'callable from blueprints' so we add the shortcuts here.

	// broadcast the flame on eventhandler event
	UFUNCTION(Category = "Gravity Blade", DisplayName = "GravityBlade Event: Call Flame ON")
	void CallFlameOnEvent()
	{
		auto Blade = Get();
		if(Blade == nullptr)
			return;

		UGravityBladeFlameEventHandler::Trigger_FlameOn(Blade);
	}

	// broadcast the flame off eventhandler event
	UFUNCTION(Category = "Gravity Blade", DisplayName = "GravityBlade Event: Call Flame OFF")
	void CallFlameOffEvent()
	{
		auto Blade = Get();
		if(Blade == nullptr)
			return;

		UGravityBladeFlameEventHandler::Trigger_FlameOff(Blade);
	}

	// Force the gravity blade to be sheathed immediately
	UFUNCTION(Category = "Gravity Blade")
	void ForceSheatheGravityBlade() 
	{
		UGravityBladeUserComponent::Get(Game::Mio).SheatheBlade(false);
	}

	UFUNCTION(Category = "Gravity Blade")
	void ForceUnSheatheGravityBlade() 
	{
		UGravityBladeUserComponent::Get(Game::Mio).UnsheatheBlade(false);
	}

}

UCLASS(Abstract)
class AGravityBladeActor : AHazeActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent OffsetComponent;

	UPROPERTY(DefaultComponent, Attach = OffsetComponent)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.bGenerateOverlapEvents = false;
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;

	AHazePlayerCharacter Player;

	FTransform PreviousFrameStartBladeTranform;
	FTransform CurrentFrameStartBladeTranform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PreviousFrameStartBladeTranform = CurrentFrameStartBladeTranform;
		CurrentFrameStartBladeTranform = ActorTransform;
	}
}