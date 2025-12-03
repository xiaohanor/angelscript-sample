
class UEditorBillboardComponent : UBillboardComponent
{
	default SetIsVisualizationComponent(true);
	default bIsEditorOnly = true;

	FString BillboardName;

	void SetSpriteName(FString SpriteName) property
	{
		BillboardName = SpriteName;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (GetWorld() != nullptr && GetWorld().IsGameWorld())
			return;

		if (!BillboardName.IsEmpty())
		{
			auto GameBillboard = Cast<UTexture2D>(Editor::LoadAsset(FName(f"/Game/Editor/EditorBillboards/{BillboardName}.{BillboardName}")));
			if (GameBillboard != nullptr)
			{
				SetSprite(GameBillboard);
				return;
			}

			auto EngineBillboard = Cast<UTexture2D>(Editor::LoadAsset(FName(f"/Engine/EditorResources/{BillboardName}.{BillboardName}")));
			if (EngineBillboard != nullptr)
			{
				SetSprite(EngineBillboard);
				return;
			}
		}
	}
};