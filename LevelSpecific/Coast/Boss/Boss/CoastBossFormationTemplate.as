enum ECoastBossFormation
{
	State24_Star,
	State20_Cross,
	State16_Sun,
	State16_Raincloud,
	State12_Drillbazz,
	State12_Sinus,
	State8_Banana,
	State4_PingPong,
}

enum ECoastBossMovementMode
{
	IdleBobbing = 0,
	Drillbazz,
	CloudRainSinus,
	PingPong,
	
	CrossDownUp,
	CrossUpDown,

	WaveDown,
	WaveUp,

	LerpIn,
}

UCLASS(Abstract)
class ACoastBossFormationTemplate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditDefaultsOnly)
	ECoastBossFormation Phase;

	UPROPERTY(EditDefaultsOnly)
	ECoastBossMovementMode MovementMode = ECoastBossMovementMode::IdleBobbing;

	TArray<UCoastBossDroneComponent> Drones;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Root.GetChildrenComponentsByClass(UCoastBossDroneComponent, true, Drones);
		Drones.Sort();
	}
};