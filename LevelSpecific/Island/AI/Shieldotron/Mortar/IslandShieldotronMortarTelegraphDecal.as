UCLASS(Abstract)
class AIslandShieldotronMortarTelegraphDecal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTelegraphDecalComponent DecalComp;
	default DecalComp.DisplayHeight = 400;

	void HideDecal()
	{
		DecalComp.HideTelegraph();
	}

	void ShowDecal()
	{
		DecalComp.ShowTelegraph();
	}
};