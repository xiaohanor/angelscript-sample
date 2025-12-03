UCLASS(Abstract)
class APrison_SnpierTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHackableSniperTurretResponseComponent ResponseComp;
};
