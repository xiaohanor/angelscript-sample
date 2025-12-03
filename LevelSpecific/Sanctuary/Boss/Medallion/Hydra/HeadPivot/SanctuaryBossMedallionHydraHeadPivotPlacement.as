enum EMedallionHydraHeadPivotPlacement
{
	Unspecified,
	GloryKill,
	Flying1_MioLeft,
	Flying1_MioRight,
	Flying1_MioBack,
	Flying1_ZoeLeft,
	Flying1_ZoeRight,
	Flying1_ZoeBack,
}

UCLASS(NotBlueprintable)
class ASanctuaryBossMedallionHydraHeadPivotPlacement : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditInstanceOnly)
	EMedallionHydraHeadPivotPlacement PlacementID;

	UPROPERTY(EditInstanceOnly)
	float AlphaBlendDuration = 0.5;

	UPROPERTY(EditInstanceOnly)
	float LerpToTransformDuration = 1.0;

	UPROPERTY(EditInstanceOnly)
	float DurationUntilStop = -1.0;
};