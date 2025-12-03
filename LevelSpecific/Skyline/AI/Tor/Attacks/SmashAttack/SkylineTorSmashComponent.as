class USkylineTorSmashComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<ASkylineTorSmashShockwave> SmashShockwaveClass;

	const int AttacksMax = 3;
}