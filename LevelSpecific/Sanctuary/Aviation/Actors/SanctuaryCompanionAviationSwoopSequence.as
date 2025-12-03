enum ESanctuaryCompanionAviationSwoopSequenceType
{
	SwoopBack,
	SwoopIn,
}

enum ESanctuaryCompanionAviationSwoopSequenceDirection
{
	TurnLeft,
	TurnRight,
}

event void FSanctuaryCompanionAviationSwoopSequencePlayEvent(AHazePlayerCharacter Player, ASanctuaryMegaCompanion MegaCompanion);
event void FSanctuaryCompanionAviationSwoopSequencePlaySwoopInEvent(AHazePlayerCharacter Player, ASanctuaryMegaCompanion MegaCompanion, ASanctuaryBossArenaHydraHead HydraLeft, ASanctuaryBossArenaHydraHead HydraRight);
event void FSanctuaryCompanionAviationSwoopSequenceEvent();

class ASanctuaryCompanionAviationSwoopSequence : AHazeLevelSequenceActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditInstanceOnly)
	EHazeSelectPlayer TargetPlayer;

	UPROPERTY(EditInstanceOnly)
	ESanctuaryCompanionAviationSwoopSequenceDirection SequenceDirection;

	UPROPERTY(EditInstanceOnly)
	ESanctuaryCompanionAviationSwoopSequenceType SequenceType;

	UPROPERTY(EditAnywhere)
	float BlendInTime = 0.2;
	
	UPROPERTY(EditAnywhere)
	float BlendOutTime = 0.2;

	FQuat StartWorldRotation;

	UPROPERTY(EditAnywhere)
	FSanctuaryCompanionAviationSwoopSequencePlaySwoopInEvent OnShouldPlaySwoopIn;
	UPROPERTY(EditAnywhere)
	FSanctuaryCompanionAviationSwoopSequencePlayEvent OnShouldPlay;
	UPROPERTY(EditAnywhere)
	FSanctuaryCompanionAviationSwoopSequenceEvent OnDone;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartWorldRotation = ActorQuat;
	}
};