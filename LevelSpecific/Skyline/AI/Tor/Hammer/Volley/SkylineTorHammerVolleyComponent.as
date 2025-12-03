class USkylineTorHammerVolleyComponent : UActorComponent
{
	USkylineTorSettings Settings;
	USkylineTorHammerComponent HammerComp;

	bool bLanded;
	FVector ImpactLocation;
	FVector TargetLocation;

	UPROPERTY()
	TSubclassOf<ASkylineTorSmashShockwave> VolleyShockwaveClass;
	float ShockwaveTime;
	bool bEnableShockwaves;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = USkylineTorSettings::GetSettings(Cast<AHazeActor>(Owner));
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
	}

	ASkylineTorSmashShockwave SpawnShockwave(ESkylineTorSmashShockwaveType Type)
	{
		ShockwaveTime = Time::GameTimeSeconds;
		ASkylineTorSmashShockwave Shockwave = SpawnActor(VolleyShockwaveClass, HammerComp.HoldHammerComp.Hammer.TopLocation.WorldLocation + Owner.ActorUpVector * Settings.SmashDamageWidth / 2, bDeferredSpawn = true, Level = Owner.Level);
		Shockwave.Owner = Cast<AHazeActor>(Owner);
		Shockwave.MaxSpeed = Settings.SmashExpansionBaseSpeed + Settings.SmashExpansionIncrementalSpeed;
		Shockwave.Type = Type;
		FinishSpawningActor(Shockwave);
		return Shockwave;
	}
}