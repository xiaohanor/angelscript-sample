UCLASS(Abstract)
class ADentistDoubleCannonLaunchedRoot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MioAttachment;

	UPROPERTY(DefaultComponent)
	USceneComponent ZoeAttachment;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ADentistDoubleCannonLaunchedRoot> BlueprintClass;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = MioAttachment)
	UDentistToothMeshPreviewComponent MioPreview;

	UPROPERTY(DefaultComponent, Attach = ZoeAttachment)
	UDentistToothMeshPreviewComponent ZoePreview;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;

	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		MioPreview.SetRelativeTransform(FTransform::Identity);
		ZoePreview.SetRelativeTransform(FTransform::Identity);
	}
#endif

	USceneComponent GetAttachmentForPlayer(EHazePlayer Player) const
	{
		switch(Player)
		{
			case EHazePlayer::Mio:
				return MioAttachment;

			case EHazePlayer::Zoe:
				return ZoeAttachment;
		}
	}

	FTransform GetAttachmentRelativeTransformForPlayer(EHazePlayer Player, bool bDefault, bool bCenter) const
	{
		FTransform RelativeTransform;
		if(bDefault)
		{
			auto DefaultLaunchedRoot = Cast<ADentistDoubleCannonLaunchedRoot>(BlueprintClass.Get().DefaultObject);
			RelativeTransform = DefaultLaunchedRoot.GetAttachmentForPlayer(Player).RelativeTransform;
		}
		else
		{
			RelativeTransform = GetAttachmentForPlayer(Player).RelativeTransform;
		}

		if(bCenter)
			RelativeTransform.SetLocation(RelativeTransform.Location + FVector(0, 0, Dentist::CollisionRadius));

		return RelativeTransform;
	}
};

#if EDITOR
/**
 * Used as a preview of the tooth mesh on ADentistDoubleCannonLaunchedRoot
 */
UCLASS(NotPlaceable, NotBlueprintable)
class UDentistToothMeshPreviewComponent : UPlayerEditorVisualizerComponent
{
	default IsVisualizationComponent = true;
	default bHiddenInGame = true;
}
#endif