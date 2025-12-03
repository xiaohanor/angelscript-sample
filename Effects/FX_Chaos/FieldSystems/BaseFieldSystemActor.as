
/**
 * Base class for the Haze Field systems. 
 */

UCLASS(Abstract)
class ABaseFieldSystemActor : AFieldSystemActor
{
#if EDITOR

	UPROPERTY(DefaultComponent, Attach = FieldSystemComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "FieldSystemActor";

#endif
}