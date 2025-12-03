UCLASS(Abstract)
class APrisonBossVoActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeVoxCharacterTemplateComponent CharacterTemplateComponent;
};
