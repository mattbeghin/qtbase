// Copyright (C) 2016 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only

#include <AppKit/AppKit.h>

#include "qcocoaaccessibility.h"
#include "qcocoaaccessibilityelement.h"
#include <QtGui/qaccessible.h>
#include <QtCore/qmap.h>
#include <private/qcore_mac_p.h>

QT_BEGIN_NAMESPACE

using namespace Qt::StringLiterals;

#if QT_CONFIG(accessibility)

QCocoaAccessibility::QCocoaAccessibility()
{

}

QCocoaAccessibility::~QCocoaAccessibility()
{

}

void QCocoaAccessibility::notifyAccessibilityUpdate(QAccessibleEvent *event)
{
    return;
}

void QCocoaAccessibility::setRootObject(QObject *o)
{
    Q_UNUSED(o);
}

void QCocoaAccessibility::initialize()
{

}

void QCocoaAccessibility::cleanup()
{

}

namespace QCocoaAccessible {

typedef QMap<QAccessible::Role, NSString *> QMacAccessibiltyRoleMap;
Q_GLOBAL_STATIC(QMacAccessibiltyRoleMap, qMacAccessibiltyRoleMap);

static void populateRoleMap()
{
    QMacAccessibiltyRoleMap &roleMap = *qMacAccessibiltyRoleMap();
    roleMap[QAccessible::MenuItem] = NSAccessibilityMenuItemRole;
    roleMap[QAccessible::MenuBar] = NSAccessibilityMenuBarRole;
    roleMap[QAccessible::ScrollBar] = NSAccessibilityScrollBarRole;
    roleMap[QAccessible::Grip] = NSAccessibilityGrowAreaRole;
    roleMap[QAccessible::Window] = NSAccessibilityWindowRole;
    roleMap[QAccessible::Dialog] = NSAccessibilityWindowRole;
    roleMap[QAccessible::AlertMessage] = NSAccessibilityWindowRole;
    roleMap[QAccessible::ToolTip] = NSAccessibilityWindowRole;
    roleMap[QAccessible::HelpBalloon] = NSAccessibilityWindowRole;
    roleMap[QAccessible::PopupMenu] = NSAccessibilityMenuRole;
    roleMap[QAccessible::Application] = NSAccessibilityApplicationRole;
    roleMap[QAccessible::Pane] = NSAccessibilityGroupRole;
    roleMap[QAccessible::Grouping] = NSAccessibilityGroupRole;
    roleMap[QAccessible::Separator] = NSAccessibilitySplitterRole;
    roleMap[QAccessible::ToolBar] = NSAccessibilityToolbarRole;
    roleMap[QAccessible::PageTab] = NSAccessibilityRadioButtonRole;
    roleMap[QAccessible::PageTabList] = NSAccessibilityTabGroupRole;
    roleMap[QAccessible::ButtonMenu] = NSAccessibilityMenuButtonRole;
    roleMap[QAccessible::ButtonDropDown] = NSAccessibilityPopUpButtonRole;
    roleMap[QAccessible::SpinBox] = NSAccessibilityIncrementorRole;
    roleMap[QAccessible::Slider] = NSAccessibilitySliderRole;
    roleMap[QAccessible::ProgressBar] = NSAccessibilityProgressIndicatorRole;
    roleMap[QAccessible::ComboBox] = NSAccessibilityComboBoxRole;
    roleMap[QAccessible::RadioButton] = NSAccessibilityRadioButtonRole;
    roleMap[QAccessible::CheckBox] = NSAccessibilityCheckBoxRole;
    roleMap[QAccessible::StaticText] = NSAccessibilityStaticTextRole;
    roleMap[QAccessible::Table] = NSAccessibilityTableRole;
    roleMap[QAccessible::StatusBar] = NSAccessibilityStaticTextRole;
    roleMap[QAccessible::Column] = NSAccessibilityColumnRole;
    roleMap[QAccessible::ColumnHeader] = NSAccessibilityColumnRole;
    roleMap[QAccessible::Row] = NSAccessibilityRowRole;
    roleMap[QAccessible::RowHeader] = NSAccessibilityRowRole;
    roleMap[QAccessible::Button] = NSAccessibilityButtonRole;
    roleMap[QAccessible::EditableText] = NSAccessibilityTextFieldRole;
    roleMap[QAccessible::Link] = NSAccessibilityLinkRole;
    roleMap[QAccessible::Indicator] = NSAccessibilityValueIndicatorRole;
    roleMap[QAccessible::Splitter] = NSAccessibilitySplitGroupRole;
    roleMap[QAccessible::List] = NSAccessibilityListRole;
    roleMap[QAccessible::ListItem] = NSAccessibilityStaticTextRole;
    roleMap[QAccessible::Cell] = NSAccessibilityCellRole;
    roleMap[QAccessible::Client] = NSAccessibilityGroupRole;
    roleMap[QAccessible::Paragraph] = NSAccessibilityGroupRole;
    roleMap[QAccessible::Section] = NSAccessibilityGroupRole;
    roleMap[QAccessible::WebDocument] = NSAccessibilityGroupRole;
    roleMap[QAccessible::ColorChooser] = NSAccessibilityColorWellRole;
    roleMap[QAccessible::Footer] = NSAccessibilityGroupRole;
    roleMap[QAccessible::Form] = NSAccessibilityGroupRole;
    roleMap[QAccessible::Heading] = @"AXHeading";
    roleMap[QAccessible::Note] = NSAccessibilityGroupRole;
    roleMap[QAccessible::ComplementaryContent] = NSAccessibilityGroupRole;
    roleMap[QAccessible::Graphic] = NSAccessibilityImageRole;
    roleMap[QAccessible::Tree] = NSAccessibilityOutlineRole;
    roleMap[QAccessible::BlockQuote] = NSAccessibilityGroupRole;
}

/*
    Returns a Cocoa accessibility role for the given interface, or
    NSAccessibilityUnknownRole if no role mapping is found.
*/
NSString *macRole(QAccessibleInterface *interface)
{
    QAccessible::Role qtRole = interface->role();
    QMacAccessibiltyRoleMap &roleMap = *qMacAccessibiltyRoleMap();

    if (roleMap.isEmpty())
        populateRoleMap();

    // MAC_ACCESSIBILTY_DEBUG() << "role for" << interface.object() << "interface role" << Qt::hex << qtRole;

    if (roleMap.contains(qtRole)) {
       // MAC_ACCESSIBILTY_DEBUG() << "return" <<  roleMap[qtRole];
        if (roleMap[qtRole] == NSAccessibilityComboBoxRole && !interface->state().editable)
            return NSAccessibilityMenuButtonRole;
        if (roleMap[qtRole] == NSAccessibilityTextFieldRole && interface->state().multiLine)
            return NSAccessibilityTextAreaRole;
        return roleMap[qtRole];
    }

    // Treat unknown Qt roles as generic group container items. Returning
    // NSAccessibilityUnknownRole is also possible but makes the screen
    // reader focus on the item instead of passing focus to child items.
    // MAC_ACCESSIBILTY_DEBUG() << "return NSAccessibilityGroupRole for unknown Qt role";
    return NSAccessibilityGroupRole;
}

/*
    Returns a Cocoa sub role for the given interface.
*/
NSString *macSubrole(QAccessibleInterface *interface)
{
    QAccessible::State s = interface->state();
    if (s.searchEdit)
        return NSAccessibilitySearchFieldSubrole;
    if (s.passwordEdit)
        return NSAccessibilitySecureTextFieldSubrole;
    if (interface->role() == QAccessible::PageTab)
        return NSAccessibilityTabButtonSubrole;
    return nil;
}

/*
    Cocoa accessibility supports ignoring elements, which means that
    the elements are still present in the accessibility tree but is
    not used by the screen reader.
*/
bool shouldBeIgnored(QAccessibleInterface *interface)
{
    return true;
}

bool defaultUnignored(QAccessibleInterface *child)
{
    if (child && child->isValid()) {
        const auto state = child->state();
        return !state.invalid && !state.invisible;
    }
    return false;
}

NSArray<QMacAccessibilityElement *> *unignoredChildren(QAccessibleInterface *interface,
                                    const std::function<bool(QAccessibleInterface *child)> &pred)
{
    int numKids = 0;
    NSMutableArray<QMacAccessibilityElement *> *kids = [NSMutableArray<QMacAccessibilityElement *> arrayWithCapacity:numKids];
    return NSAccessibilityUnignoredChildren(kids);
}

/*
    Translates a predefined QAccessibleActionInterface action to a Mac action constant.
    Returns 0 if the Qt Action has no mac equivalent. Ownership of the NSString is
    not transferred.
*/
NSString *getTranslatedAction(const QString &qtAction)
{
    return nil;
}


/*
    Translates between a Mac action constant and a QAccessibleActionInterface action
    Returns an empty QString if there is no Qt predefined equivalent.
*/
QString translateAction(NSString *nsAction, QAccessibleInterface *interface)
{
    return QString();
}

bool hasValueAttribute(QAccessibleInterface *interface)
{
    return false;
}

id getValueAttribute(QAccessibleInterface *interface)
{
    return nil;
}

} // namespace QCocoaAccessible

#endif // QT_CONFIG(accessibility)

QT_END_NAMESPACE

