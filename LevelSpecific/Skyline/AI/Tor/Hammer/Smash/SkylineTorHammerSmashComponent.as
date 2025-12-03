class USkylineTorHammerSmashComponent : UActorComponent
{
	bool bLanded;
	FVector ImpactLocation;
	FVector TargetLocation;
	int AttackNum;

	UPROPERTY()
	TSubclassOf<ASkylineTorSmashShockwave> ShockwaveClass;
}