struct FSkylineDroneBossAttachmentSpawnedData
{
	UPROPERTY(BlueprintReadOnly)
	ASkylineDroneBossAttachment Attachment;
}

struct FSkylineDroneBossAttachmentConnectedData
{
	UPROPERTY(BlueprintReadOnly)
	ASkylineDroneBossAttachment Attachment;
}

struct FSkylineDroneBossAttachmentDestroyedData
{
	UPROPERTY(BlueprintReadOnly)
	ASkylineDroneBossAttachment Attachment;

	UPROPERTY(BlueprintReadOnly)
	FVector Location;
}

UCLASS(Abstract)
class USkylineDroneBossEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotVisible, BlueprintReadOnly)
	ASkylineDroneBoss Boss = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASkylineDroneBoss>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttachmentSpawned(FSkylineDroneBossAttachmentSpawnedData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttachmentConnected(FSkylineDroneBossAttachmentConnectedData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttachmentDestroyed(FSkylineDroneBossAttachmentDestroyedData Data) {}
}