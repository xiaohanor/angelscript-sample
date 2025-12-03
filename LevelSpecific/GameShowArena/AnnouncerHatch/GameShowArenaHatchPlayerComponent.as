event void FGameShowHatchPlayerBombDunkEvent(AHazePlayerCharacter Player);
class UGameShowArenaHatchPlayerComponent : UActorComponent
{
	UPROPERTY()
	FGameShowHatchPlayerBombDunkEvent OnBombDunk;

	bool bFinalSequenceCompleted = false;

	AGameShowArenaAnnouncer EndingAnnouncer;

	AHazePlayerCharacter Player;
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION()
	void TriggerBombDunk()
	{
		OnBombDunk.Broadcast(Cast<AHazePlayerCharacter>(Owner));
	}

	UFUNCTION()
	void AttachHatchToPlayer()
	{
		FName AttachSocket = n"Align";
		EndingAnnouncer.HatchMeshComp.AttachToComponent(Player.Mesh, AttachSocket, EAttachmentRule::KeepWorld);
	}
};