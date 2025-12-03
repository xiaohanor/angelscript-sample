//vfx_enemy_gemtrap_trail_01
class ASolarFlareFireBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FireBall;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SolarFlareFireBallCapability");

	ASolarFlareShuttle Shuttle;

	float MoveSpeed = 12500.0;
	float MinActivateRange;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Shuttle = TListedActors<ASolarFlareShuttle>().GetSingle();
		MinActivateRange = MoveSpeed * 12.0;
	}

	bool IsWithinRange()
	{
		return (Shuttle.ActorLocation - ActorLocation).Size() < MinActivateRange;
	}
}