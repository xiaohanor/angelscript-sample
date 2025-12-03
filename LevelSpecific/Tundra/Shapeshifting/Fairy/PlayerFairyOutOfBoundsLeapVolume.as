UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass)
class APlayerFairyOutOfBoundsLeapVolume : APlayerTrigger
{
	default bTriggerForZoe = true;
	default bTriggerForMio = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		devCheck(!bTriggerForMio, "Out of bounds leap volume will trigger for Mio, this makes no sense and will lead to errors");
	}

	void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerEnter(Player);
		
		auto FairyComp = UTundraPlayerFairyComponent::Get(Player);
		FairyComp.AddOutOfBoundsLeapInstigator(this);
	}

	void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerLeave(Player);
		
		auto FairyComp = UTundraPlayerFairyComponent::Get(Player);
		FairyComp.RemoveOutOfBoundsLeapInstigator(this);
	}
}