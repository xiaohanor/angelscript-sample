struct FTundraPlayerSnowMonkeyGroundSlamResponseEffectParams
{
	ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType;
}

class UTundraPlayerSnowMonkeyGroundSlamResponseEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ResponseComp = UTundraPlayerSnowMonkeyGroundSlamResponseComponent::Get(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundSlam(FTundraPlayerSnowMonkeyGroundSlamResponseEffectParams Params) {}
}

event void FTundraPlayerSnowMonkeyOnGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType, FVector PlayerLocation);

enum ETundraPlayerSnowMonkeyGroundSlamType
{
	Grounded,
	Airborne,
	MAX
}

class UTundraPlayerSnowMonkeyGroundSlamResponseComponent : UActorComponent
{
	UPROPERTY()
	FTundraPlayerSnowMonkeyOnGroundSlam OnGroundSlam;

	/* If false the event wont get called and the effect will always play regardless of the bWithGroundSlamEffect setting */
	UPROPERTY(EditAnywhere, BlueprintHidden)
	private bool bEnabled = true;

	/* If true, will get called on both control and remote, if false only on control */
	UPROPERTY(EditAnywhere)
	bool bCallOnGroundSlamOnRemote = true;

	/* If true will set the control side to the player controlling the monkey (Mio) */
	UPROPERTY(EditAnywhere)
	bool bSetControlSideInBeginPlay = true;

	/* If true it will play vfx with the ground slam, otherwise it will not */
	UPROPERTY(EditAnywhere)
	bool bWithGroundSlamEffect = true;

	TArray<UPrimitiveComponent> ComponentsToTriggerOn;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		devCheck(Owner.IsA(AHazeActor), "Ground slam response components cannot be placed on non-HazeActors");

		if(bSetControlSideInBeginPlay)
			Owner.SetActorControlSide(Game::Mio);
	}

	UFUNCTION()
	void EnableResponseComponent()
	{
		bEnabled = true;
	}

	UFUNCTION()
	void DisableResponseComponent()
	{
		bEnabled = false;
	}

	UFUNCTION(BlueprintProtected)
	bool IsResponseComponentEnabled()
	{
		return bEnabled;
	}
}

/** GroundSlamResponseSelectorComponents are supposed to be used on actors that also has a GroundSlamResponseComponent, 
the parent of this component (if it is a primitive component) will be selected as a mesh that if impacted by ground slam will trigger the response, 
if none of these are present on the actor, all primitive components will be slammable */
class UTundraGroundSlamResponseSelectorComponent : USceneComponent
{
	/* If true, will check in the hierarchy for parents of the direct parent and add all primitive components it can find to be slammable */
	UPROPERTY(EditAnywhere)
	bool bIncludeAllParents = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto ResponseComp = UTundraPlayerSnowMonkeyGroundSlamResponseComponent::Get(Owner);
		TArray<USceneComponent> Parents;
		GetParentComponents(Parents);

		for(auto Parent : Parents)
		{
			auto Primtive = Cast<UPrimitiveComponent>(Parent);
			if(Primtive != nullptr)
				ResponseComp.ComponentsToTriggerOn.Add(Primtive);

			if(!bIncludeAllParents)
				break;
		}
	}
}