namespace ForceFeedback
{

asset Default_Light of UForceFeedbackEffect
{
	FForceFeedbackChannelDetails Channel;
	Channel.bAffectsLeftLarge = true;
	Channel.bAffectsRightLarge = true;
	Channel.Curve.ExternalCurve = Curves::LightForceFeedbackCurve;

	ChannelDetails.SetNum(1);
	ChannelDetails[0] = Channel;
}

asset Default_Very_Light of UForceFeedbackEffect
{
	FForceFeedbackChannelDetails Channel;
	Channel.bAffectsLeftLarge = true;
	Channel.bAffectsRightLarge = true;
	Channel.Curve.ExternalCurve = Curves::VeryLightForceFeedbackCurve;

	ChannelDetails.SetNum(1);
	ChannelDetails[0] = Channel;
}

asset Default_Light_Tap of UForceFeedbackEffect
{
	FForceFeedbackChannelDetails Channel;
	Channel.bAffectsRightLarge = true;
	Channel.Curve.ExternalCurve = Curves::LightTapForceFeedbackCurve;

	ChannelDetails.SetNum(1);
	ChannelDetails[0] = Channel;
}

asset Default_Medium of UForceFeedbackEffect
{
	FForceFeedbackChannelDetails Channel;
	Channel.bAffectsLeftLarge = true;
	Channel.bAffectsRightLarge = true;
	Channel.Curve.ExternalCurve = Curves::MediumForceFeedbackCurve;

	ChannelDetails.SetNum(1);
	ChannelDetails[0] = Channel;
}

asset Default_Medium_Short of UForceFeedbackEffect
{
	FForceFeedbackChannelDetails Channel;
	Channel.bAffectsLeftLarge = true;
	Channel.bAffectsRightLarge = true;
	Channel.Curve.ExternalCurve = Curves::MediumShortForceFeedbackCurve;

	ChannelDetails.SetNum(1);
	ChannelDetails[0] = Channel;
}

asset Default_Heavy of UForceFeedbackEffect
{
	FForceFeedbackChannelDetails Channel;
	Channel.bAffectsLeftLarge = true;
	Channel.bAffectsRightLarge = true;
	Channel.Curve.ExternalCurve = Curves::HeavyForceFeedbackCurve;

	ChannelDetails.SetNum(1);
	ChannelDetails[0] = Channel;
}

asset Default_Heavy_Short of UForceFeedbackEffect
{
	FForceFeedbackChannelDetails Channel;
	Channel.bAffectsLeftLarge = true;
	Channel.bAffectsRightLarge = true;
	Channel.Curve.ExternalCurve = Curves::HeavyShortForceFeedbackCurve;

	ChannelDetails.SetNum(1);
	ChannelDetails[0] = Channel;
}

namespace Curves
{


asset LightForceFeedbackCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	0.5 |''''''''''''''····....                                          |
	    |                      ''···..                                   |
	    |                             ''·..                              |
	    |                                  '·..                          |
	    |                                      '·.                       |
	    |                                         '·.                    |
	    |                                            '·.                 |
	    |                                               ·.               |
	    |                                                 '·             |
	    |                                                   '·           |
	    |                                                     '·         |
	    |                                                       '.       |
	    |                                                         '.     |
	    |                                                           ·    |
	    |                                                            '.  |
	0.0 |                                                              '.|
	    ------------------------------------------------------------------
	    0.0                                                            0.3
	*/
	AddAutoCurveKey(0.0, 0.5);
	AddCurveKeyBrokenTangent(0.3, 0.0, -4.466806, -16.90559);
}

asset VeryLightForceFeedbackCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	0.2 |'''''''''''····...                                              |
	    |                  '''··..                                       |
	    |                         ''·..                                  |
	    |                              ''·.                              |
	    |                                  ''·.                          |
	    |                                      '·.                       |
	    |                                         '·.                    |
	    |                                            '·.                 |
	    |                                               '.               |
	    |                                                 '·.            |
	    |                                                    ·.          |
	    |                                                      '.        |
	    |                                                        '.      |
	    |                                                          '.    |
	    |                                                            '.  |
	0.0 |                                                              ·.|
	    ------------------------------------------------------------------
	    0.0                                                           0.25
	*/
	AddAutoCurveKey(0.0, 0.2);
	AddCurveKeyBrokenTangent(0.25, 0.0, -1.82057, -16.90559);
}

asset LightTapForceFeedbackCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	0.7 |'''··..                                                         |
	    |       '··.                                                     |
	    |           ''·..                                                |
	    |                '·.                                             |
	    |                   ''·.                                         |
	    |                       '·.                                      |
	    |                          '·..                                  |
	    |                              '·.                               |
	    |                                 '·.                            |
	    |                                    '·.                         |
	    |                                       '··.                     |
	    |                                           '·.                  |
	    |                                              '··.              |
	    |                                                  '·..          |
	    |                                                      '··.      |
	0.0 |                                                          ''··..|
	    ------------------------------------------------------------------
	    0.0                                                            0.1
	*/
	AddCurveKeyTangent(0.0, 0.7, -3.647571);
	AddCurveKeyBrokenTangent(0.1, 0.0, -4.503045, -16.90559);
}

asset MediumForceFeedbackCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	0.75|''''''''''''''·····...                                          |
	    |                      '''··..                                   |
	    |                             ''·..                              |
	    |                                  '··.                          |
	    |                                      '·.                       |
	    |                                         '·.                    |
	    |                                            '·.                 |
	    |                                               '.               |
	    |                                                 '·             |
	    |                                                   '·           |
	    |                                                     '·         |
	    |                                                       '·       |
	    |                                                         '.     |
	    |                                                           ·    |
	    |                                                            '·  |
	0.0 |                                                              '.|
	    ------------------------------------------------------------------
	    0.0                                                           0.45
	*/
	AddAutoCurveKey(0.0, 0.75);
	AddCurveKeyBrokenTangent(0.45, 0.0, -4.498049, -4.498056);
}

asset MediumShortForceFeedbackCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	0.62|''·.                                                            |
	    |    ''·.                                                        |
	    |        ''·.                                                    |
	    |            ''·.                                                |
	    |                ''·.                                            |
	    |                    ''·.                                        |
	    |                        '··.                                    |
	    |                            '··.                                |
	    |                                '··.                            |
	    |                                    '··.                        |
	    |                                        '··.                    |
	    |                                            '·..                |
	    |                                                '·..            |
	    |                                                    '·..        |
	    |                                                        '·..    |
	0.0 |                                                            '·..|
	    ------------------------------------------------------------------
	    0.01                                                          0.15
	*/
	AddCurveKeyTangent(0.016644, 0.628333, -4.478192);
	AddCurveKeyBrokenTangent(0.156913, 0.0, -4.498049, -4.498056);
}

asset HeavyForceFeedbackCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.00|'''''''''''''''''''''····...                                    |
	    |                            '''·..                              |
	    |                                  ''·.                          |
	    |                                      ''·.                      |
	    |                                          '·.                   |
	    |                                             '.                 |
	    |                                               '·               |
	    |                                                 '·             |
	    |                                                   '·           |
	    |                                                     '.         |
	    |                                                       '.       |
	    |                                                         ·      |
	    |                                                          '.    |
	    |                                                            .   |
	    |                                                             ·  |
	0.0 |                                                              '.|
	    ------------------------------------------------------------------
	    0.0                                                            0.6
	*/
	AddAutoCurveKey(0.0, 1.0);
	AddCurveKeyBrokenTangent(0.6, 0.0, -5.360168, -5.360189);
}

asset HeavyShortForceFeedbackCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.43|''··..                                                          |
	    |      ''·..                                                     |
	    |           '··.                                                 |
	    |               ''·..                                            |
	    |                    '·.                                         |
	    |                       ''·.                                     |
	    |                           ''·.                                 |
	    |                               '·..                             |
	    |                                   '·.                          |
	    |                                      '··.                      |
	    |                                          '·.                   |
	    |                                             ''·.               |
	    |                                                 '·.            |
	    |                                                    ''·.        |
	    |                                                        '·..    |
	0.0 |                                                            '·..|
	    ------------------------------------------------------------------
	    0.13                                                          0.25
	*/
	AddCurveKeyTangent(0.138441, 1.430832, -7.807468);
	AddCurveKeyBrokenTangent(0.259274, 0.0, -12.128813, -5.360189);
}

}

}