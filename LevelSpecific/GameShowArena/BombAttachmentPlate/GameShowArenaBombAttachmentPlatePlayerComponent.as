UCLASS(Abstract)
class UGameShowArenaBombAttachmentPlatePlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AGameShowArenaBombAttachmentPlate> AttachmentPlateClass;

	AGameShowArenaBombAttachmentPlate AttachmentPlate;
	
	FName AttachmentBone = n"Spine2";
};